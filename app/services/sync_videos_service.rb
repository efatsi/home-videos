class SyncVideosService
  VIDEO_EXTENSIONS = %w[.mp4 .mov .avi .m4v .mkv .webm].freeze

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

      GenerateThumbnailJob.perform_later(video.id)
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
end
