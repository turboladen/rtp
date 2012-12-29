module RTP
  module FFmpeg
    AVFieldOrder = enum :unknown,
                        :progressive,
                        :tt,
                        :bb,
                        :tb,
                        :bt
  end
end