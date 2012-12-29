module RTP
  module FFmpeg
    AVColorPrimaries = enum :bt709, 1,
                            :unspecified, 2,
                            :bt470m, 4,
                            :bt470bg, 5,
                            :smpte170m, 6,
                            :smpte240m, 7,
                            :film, 8,
                            :nb
  end
end