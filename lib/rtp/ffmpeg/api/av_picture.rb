module RTP
  module FFmpeg
    class AVPicture < FFI::Struct
      layout  :data, [:pointer, AV_NUM_DATA_POINTERS],
              :linesize, [:int, AV_NUM_DATA_POINTERS]
    end
  end
end