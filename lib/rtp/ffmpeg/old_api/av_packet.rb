module RTP
  module FFmpeg
    class AVPacket < FFI::Struct
      layout  :pts, :long,
              :dts, :long,
              :data, :pointer,
              :size, :int,
              :stream_index, :int,
              :flags, :int,
              :duration, :int,
              :destruct, :pointer,
              :priv, :pointer,
              :pos, :long,
              :convergence_duration, :long
    end
  end
end
