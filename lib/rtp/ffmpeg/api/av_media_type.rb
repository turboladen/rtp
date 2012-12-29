module RTP
  module FFmpeg
    AVMediaType = enum :unknown, -1,
                       :video,
                       :audio,
                       :data,
                       :subtitle,
                       :attachment,
                       :nb            # new

  end
end