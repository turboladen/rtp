module RTP
  module FFmpeg
    class AVProbeData < FFI::Struct
      layout  :filename, :string,
              :buf, :pointer,
              :buf_size, :int
    end
  end
end
