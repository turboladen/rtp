module RTP
  module FFmpeg
    AVColorSpace = enum :rgb, 0,
                        :bt709, 1,
                        :unspecified, 2,
                        :fcc, 4,
                        :bt470bg, 5,
                        :smpte170m, 6,
                        :smpte240m, 7,
                        :ycocg, 8,
                        :nb
  end
end