require "shellwords"

class SyncVideosService
  VIDEO_EXTENSIONS = %w[.mp4 .mov .avi .m4v .mkv .webm].freeze
  THUMBNAIL_PREFIX = "thumbnails/".freeze

  def self.call
    new.call
  end

  def call
    puts "Scanning Spaces bucket: #{bucket}"
    video_objects.each do |object|
      if Video.exists?(spaces_key: object.key)
        puts "  skip (exists): #{object.key}"
        next
      end

      puts "  creating: #{object.key}"
      video = Video.create!(
        spaces_key:  object.key,
        title:       title_from_key(object.key),
        recorded_at: recorded_at_from_key(object.key) || object.last_modified,
        file_size:   object.size
      )

      generate_thumbnail(video)
    end

    puts "Sync complete."
  end

  private

  def bucket
    ENV["SPACES_BUCKET"]
  end

  def video_objects
    SPACES_CLIENT
      .list_objects_v2(bucket: bucket)
      .contents
      .select { |obj| VIDEO_EXTENSIONS.include?(File.extname(obj.key).downcase) }
  end

  def title_from_key(key)
    File.basename(key, ".*").gsub(/[-_]/, " ").split.map(&:capitalize).join(" ")
  end

  def recorded_at_from_key(key)
    filename = File.basename(key, ".*")
    if (match = filename.match(/(\d{4})[-_]?(\d{2})[-_]?(\d{2})/))
      Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
    end
  rescue
    nil
  end

  def generate_thumbnail(video)
    ext = File.extname(video.spaces_key)
    basename = File.basename(video.spaces_key, ext)
    thumbnail_key = "#{THUMBNAIL_PREFIX}#{basename}.jpg"

    Dir.mktmpdir do |tmpdir|
      video_path     = File.join(tmpdir, "video#{ext}")
      thumbnail_path = File.join(tmpdir, "thumb.jpg")

      # Download video from Spaces
      SPACES_CLIENT.get_object(
        bucket: bucket,
        key:    video.spaces_key,
        response_target: video_path
      )

      # Extract a frame at 2 seconds (or 0 if shorter)
      system("ffmpeg -y -ss 2 -i #{video_path.shellescape} -vframes 1 -q:v 3 #{thumbnail_path.shellescape} 2>/dev/null")

      unless File.exist?(thumbnail_path)
        puts "  ffmpeg failed for #{video.spaces_key}, skipping thumbnail"
        return
      end

      # Get duration from ffprobe
      duration_output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{video_path.shellescape} 2>/dev/null`
      duration = duration_output.strip.to_f.to_i

      # Upload thumbnail to Spaces
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
      puts "  thumbnail generated: #{thumbnail_key}"
    end
  rescue => e
    puts "  error generating thumbnail for #{video.spaces_key}: #{e.message}"
  end
end
