class Video < ApplicationRecord
  SPACES_ENDPOINT = ENV["SPACES_ENDPOINT"]
  SPACES_BUCKET   = ENV["SPACES_BUCKET"]

  validates :spaces_key, presence: true, uniqueness: true

  scope :chronological, -> { order(recorded_at: :asc) }
  scope :recent_first,  -> { order(recorded_at: :desc) }

  def thumbnail_url
    return nil unless thumbnail_key
    "#{SPACES_ENDPOINT}/#{SPACES_BUCKET}/#{thumbnail_key}"
  end

  def video_url
    "#{SPACES_ENDPOINT}/#{SPACES_BUCKET}/#{spaces_key}"
  end
end
