class VideosController < ApplicationController
  def index
    videos = Video.where.not(recorded_at: nil).recent_first
    @grouped_videos = videos.group_by { |v| v.recorded_at.year }
  end

  def show
    @video = Video.find(params[:id])
  end
end
