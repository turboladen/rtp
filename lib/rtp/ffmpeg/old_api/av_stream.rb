require_relative '../api/av_discard'
require_relative '../api/av_frac'
require_relative '../api/av_packet_list'
require_relative '../api/av_probe_data'
require_relative '../api/av_rational'
require_relative 'av_packet'


module RTP
  module FFmpeg
    class AVStream < FFI::Struct
      layout  :index, :int,
              :id, :int,
              :codec, :pointer,
              :r_frame_rate, AVRational,
              :priv_data, :pointer,
              :first_dts, :long_long,
              :pts, AVFrac,
              :time_base, AVRational,
              :pts_wrap_bits, :int,
              :stream_copy, :int,
              :discard, AVDiscard,
              :quality, :float,
              :start_time, :long_long,
              :duration, :long_long,
              :language, [:char, 4],
              :need_parsing, :int,          # enum AVStreamParseType,
              :parser, :pointer,
              :cur_dts, :long_long,
              :last_IP_duration, :int,
              :last_IP_pts, :long_long,
              :index_entries, :pointer,
              :nb_index_entries, :int,
              :index_entries_allocated_size, :uint,
              :nb_frames, :long_long,
              :unused, [:long_long, 5],
              :filename, :string,
              :disposition, :int,
              :probe_data, AVProbeData,
              :pts_buffer, [:long_long, MAX_REORDER_DELAY + 1],
              :sample_aspect_ratio, AVRational,
              :metadata, :pointer,
              :cur_ptr, :pointer,
              :cur_len, :int,
              :cur_pkt, AVPacket,
              :reference_dts, :long_long,
              :probe_packets, :int,
              :last_in_packet_buffer, AVPacketList,
              :avg_frame_rate, AVRational,
              :codec_info_nb_frames, :int

      def codec
        AVCodecContext.new send(:[], :codec)
      end

      def to_s
        '#<AVStream:0x%08x index=%d, id=%d, codec_type=:%s>' %
            [ object_id, self[:index], self[:id], codec[:codec_type] ]
      end

      def discard=(type)
        send(:[]=, :discard, type)
      end
    end
  end
end
