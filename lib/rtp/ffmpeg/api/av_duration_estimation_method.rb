module RTP
  module FFmpeg
    AVDurationEstimationMethod = enum :pts,
                                      :stream,
                                      :bitrate
  end
end