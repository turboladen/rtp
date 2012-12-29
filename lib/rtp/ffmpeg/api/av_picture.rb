module RTP
  module FFmpeg
    class AVPicture < FFI::Struct
      layout  :data, [:pointer, 4],
              :linesize, [:int, 4]
    end
  end
end