module RTP
  module FFmpeg
    AVChromaLocation = enum :unspecified,
                            :left,
                            :center,
                            :topleft,
                            :top,
                            :bottomleft,
                            :bottom,
                            :nb
  end
end