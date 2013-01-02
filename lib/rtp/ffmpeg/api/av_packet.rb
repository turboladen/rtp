require_relative 'av_packet_side_data_type'


module RTP
  module FFmpeg
    class SideData < FFI::Struct
      layout :data, :pointer,
             :size, :int,
             :type, AVPacketSideDataType      # TODO enum AVPacketSideDatatype
    end

    class AVPacket < FFI::Struct
      layout  :pts, :int64,
              :dts, :int64,
              :data, :pointer,
              :size, :int,
              :stream_index, :int,
              :flags, :int,
              :side_data, SideData,
              :side_data_elems, :int,
              :duration, :int,
              :destruct, :pointer,
              :priv, :pointer,
              :pos, :int64,
              :convergence_duration, :int64
    end
  end
end
