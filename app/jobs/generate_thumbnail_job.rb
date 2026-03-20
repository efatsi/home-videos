require "shellwords"

class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  THUMBNAIL_PREFIX = "thumbnails/".freeze

  def perform(video_id)
    video = Video.find(video_id)
    ext = File.extname(video.spaces_key)
    basename = File.basename(video.spaces_key, ext)
    thumbnail_key = "#{THUMBNAIL_PREFIX}#{basename}.jpg"

    Dir.mktmpdir do |tmpdir|
      video_path     = File.join(tmpdir, "video#{ext}")
      thumbnail_path = File.join(tmpdir, "thumb.jpg")

      SPACES_CLIENT.get_object(
        bucket: bucket,
        key:    video.spaces_key,
        response_target: video_path
      )

      system("ffmpeg -y -ss 2 -i #{video_path.shellescape} -vframes 1 -q:v 3 #{thumbnail_path.shellescape} 2>/dev/null")

      raise "ffmpeg failed for #{video.spaces_key}" unless File.exist?(thumbnail_path)

      duration_output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{video_path.shellescape} 2>/dev/null`
      duration = duration_output.strip.to_f.to_i

      File.open(thumbnail_path, "rb") do |file|
        SPACES_CLIENT.put_object(
          bucket:       bucket,
          key:          thumbnail_key,
          body:         file,
          content_type: "image/jpeg",
          acl:          "public-read"
        )
      end

      video.update!(thumbnail_key: thumbnail_key, duration: duration)
      Rails.logger.info "GenerateThumbnailJob: thumbnail generated for #{video.spaces_key}"
    end
  end

  private

  def bucket
    ENV["SPACES_BUCKET"]
  end
end
