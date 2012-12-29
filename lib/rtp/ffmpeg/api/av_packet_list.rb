module RTP
  module FFmpeg
    class AVPacketList < FFI::Struct
      layout  :pkt, AVPacket,
              :next, :pointer
    end
  end
end
