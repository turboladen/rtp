require_relative 'av_rational'
require_relative 'av_picture_type'


module RTP
  module FFmpeg
    class AVFrame < FFI::Struct
      layout  :data, [:pointer, 4],
              :linesize, [:int, 4],
              :extended_data, :pointer,       # new!
              :width, :int,                   # new!
              :height, :int,                  # new!
              :nb_samples, :int,              # new!
              :format, :int,                  # new!
              :key_frame, :int,
              :pict_type, AVPictureType,
              :base, [:pointer, 4],
              :sample_aspect_ratio, AVRational,       # new!
              :pts, :int64,
              :pkt_pts, :int64,               # new!
              :pkt_dts, :int64,               # new!
              :coded_picture_number, :int,
              :display_picture_number, :int,
              :quality, :int,
              :reference, :int,
              :qscale_table, :pointer,
              :qstride, :int,
              :qscale_type, :int,
              :mbskip_table, :pointer,
              :motion_val, [:pointer, 2],
              :mb_type, :pointer,
              :dct_coeff, :pointer,
              :ref_index, [:pointer, 2],
              :opaque, :pointer,
              :error, [:uint64, 4],
              :type, :int,
              :repeat_pict, :int,
              :interlaced_frame, :int,
              :top_field_first, :int,
              :palette_has_changed, :int,
              :buffer_hints, :int,
              :pan_scan, :pointer,
              :reordered_opaque, :int64,
              :hwaccel_picture_private, :pointer,     # new!
              :owner, :pointer,                       # new!
              :thread_opaque, :pointer,               # new!
              :motion_subsample_log2, :uint8,
              :sample_rate, :int,                     # new!
              :channel_layout, :uint64,               # new!
              :best_effort_timestamp, :int64,         # new!
              :pkt_pos, :int64,                       # new!
              :pkt_duration, :int64,                  # new!
              :metadata, :pointer,                    # new!
              :decode_error_flags, :int,              # new!
              :channels, :int64,                      # new!
              :pkt_size, :int                         # new!

=begin
              :age, :int,
              :qscale_type, :int,
=end
    end
  end
end