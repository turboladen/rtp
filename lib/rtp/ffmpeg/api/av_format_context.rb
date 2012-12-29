require_relative 'av_codec_id'
require_relative 'av_duration_estimation_method'
require_relative 'av_io_interrupt_cb'


module RTP
  module FFmpeg
    class AVFormatContext < FFI::Struct
      layout  :av_class,      :pointer,
              :iformat,       :pointer,
              :oformat,       :pointer,
              :priv_data,     :pointer,
              :pb,            :pointer,
              :ctx_flags,     :int,
              :nb_streams,    :uint,
              :streams,       :pointer,
              :filename,      [:char, 1024],
              :start_time,    :int64,
              :duration,      :int64,
              :bit_rate,      :int,
              :packet_size,   :uint,
              :max_delay,     :int,
              :flags,         :int,
              :probesize,     :uint,
              :max_analyze_duration,  :int,
              :key,           :pointer,
              :keylen,        :int,
              :nb_programs,   :uint,
              :programs,      :pointer,
              :video_codec_id,  AVCodecID,
              :audio_codec_id,  AVCodecID,
              :subtitle_codec_id, AVCodecID,
              :max_index_size,  :uint,
              :max_picture_buffer,  :uint,
              :nb_chapters,   :uint,
              :chapters,      :pointer,
              :metadata,      :pointer,
              :start_time_realtime, :int64,
              :fps_probe_size,  :int,       # new!
              :error_recognition,  :int,       # new!
              :interrupt_callback,  AVIOInterruptCB,       # new!
              :debug,         :int,
              :ts_id,         :int,         # new!
              :audio_preload, :int,         # new!
              :max_chunk_duration, :int,    # new!
              :max_chunk_size,      :int,   # new!
              :use_wallclock_as_timestamps,   :int,     # new!
              :avoid_negative_ts,   :int,     # new!
              :avio_flags,  :int,           # new!
              :duration_estimation_method, AVDurationEstimationMethod,  # new
              #:skip_initial_bytes,  :uint,    # new!
              #:correct_ts_overflow, :uint,    # new!
              :packet_buffer, :pointer,
              :packet_buffet_end, :pointer,
              :data_offset, :int64,
              :raw_packet_buffer, :pointer,
              :raw_packet_buffer_end, :pointer,
              :parse_queue,   :pointer,       # new!
              :parse_queue_end, :pointer,     # new!
              :raw_packet_buffer_remaining_size, :int

=begin
              :timestamp,     :long_long,
              :title,         [:char, 512],
              :author,        [:char, 512],
              :copyright,     [:char, 512],
              :comment,       [:char, 512],
              :album,         [:char, 512],
              :year,          :int,
              :track,         :int,
              :genre,         [:char, 32],
              :file_size,     :long_long,
              :cur_st,        :pointer,
              :cur_ptr_deprecated,  :pointer,
              :cur_len_deprecated,  :int,
              :cur_pkt_deprecated,  AVPacket,
              :index_build,   :int,
              :mux_rate,      :int,
              :loop_output,   :int,
              :loop_input,    :int,
=end
    end
  end
end