module RTP
  module FFmpeg
    class AVIOInterruptCB < FFI::Struct
      layout :callback, :pointer,
             :opaque, :pointer
    end
  end
end