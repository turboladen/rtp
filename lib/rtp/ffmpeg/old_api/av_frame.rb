module RTP
  module FFmpeg
    class AVFrame < FFI::Struct
      layout  :data, [:pointer, 4],
              :linesize, [:int, 4],
              :base, [:pointer, 4],
              :key_frame, :int,
              :pict_type, :int,
              :pts, :int64,
              :coded_picture_number, :int,
              :display_picture_number, :int,
              :quality, :int,
              :age, :int,
              :reference, :int,
              :qscale_table, :pointer,
              :qstride, :int,
              :mbskip_table, :pointer,
              :motion_val, [:pointer, 2],
              :mb_type, :pointer,
              :motion_subsample_log2, :uint8,
              :opaque, :pointer,
              :error, [:uint64, 4],
              :type, :int,
              :repeat_pict, :int,
              :qscale_type, :int,
              :interlaced_frame, :int,
              :top_field_first, :int,
              :pan_scan, :pointer,
              :palette_has_changed, :int,
              :buffer_hints, :int,
              :dct_coeff, :pointer,
              :ref_index, [:pointer, 2],
              :reordered_opaque, :long_long
    end
  end
end