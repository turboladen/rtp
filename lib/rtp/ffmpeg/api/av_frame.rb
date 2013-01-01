require_relative 'av_rational'
require_relative 'av_picture_type'


module RTP
  module FFmpeg
    class AVFrame < FFI::Struct
      layout  :data, [:pointer, AV_NUM_DATA_POINTERS],
              :linesize, [:int, AV_NUM_DATA_POINTERS],
              :extended_data, :pointer,       # new!
              :width, :int,                   # new!
              :height, :int,                  # new!
              :nb_samples, :int,              # new!
              :format, :int,                  # new!
              :key_frame, :int,
              :pict_type, AVPictureType,
              :base, [:pointer, AV_NUM_DATA_POINTERS],
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
              :error, [:uint64, AV_NUM_DATA_POINTERS],
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


      def to_hash
        hash = {}

        members.each_with_index do |member, i|
          value = values.at(i)

          hash[member] = case value.class.name
          when 'RTP::FFmpeg::AVRational'
            value[:den].zero? ? value[:num] : value.to_f
          when 'RTP::FFmpeg::AVFrac'
            value[:den].zero? ? value[:val] : value.to_f
          else
            value
          end
        end

        hash
      end
    end
  end
end