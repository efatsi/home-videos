module ApplicationHelper
  def format_duration(seconds)
    return unless seconds
    h = seconds / 3600
    m = (seconds % 3600) / 60
    s = seconds % 60
    h > 0 ? format("%d:%02d:%02d", h, m, s) : format("%d:%02d", m, s)
  end
end
