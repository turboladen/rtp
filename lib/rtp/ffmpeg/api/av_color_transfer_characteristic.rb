module RTP
  module FFmpeg
    AVColorTransferCharacteristic = enum :bt709, 1,
                                         :unspecified, 2,
                                         :gamma22, 4,
                                         :gamma28, 5,
                                         :smpte240m, 7,
                                         :nb
  end
end