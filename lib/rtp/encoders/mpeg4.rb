require_relative '../packet'
require_relative '../logger'


module RTP
  module Encoders
    class MPEG4
      include LogSwitch::Mixin


      CLOCK = 90000
      PACKET_SPLIT_SIZE = 1300
      PACKET_SPLIT_THRESHOLD = 1500

      attr_reader :send_frequency

      def initialize(frame_rate)
        @frame_rate = frame_rate
        packets_per_second = CLOCK / @frame_rate.to_f
        @send_frequency = 60 / packets_per_second
        log "Frame rate: #{@frame_rate}"
        log "Send frequency: #{@send_frequency}"
        @timestamp = rand(4294967295)
        @encode_queue = EM::Queue.new
      end

      def encode(av_packet, ssrc, &block)
        @encode_queue << av_packet

        processor = proc do |av_packet|
          if av_packet.size > PACKET_SPLIT_THRESHOLD
            log "#{__id__} Got big packet: #{av_packet.size}.  Splitting..."
            chunks = av_packet.scan(/.{1,#{PACKET_SPLIT_SIZE}}/m)

            until chunks.empty?
              chunk = chunks.pop
              last_in_vop = chunks.empty? ? true : false
              block.call(encode_packet(chunk, ssrc, last_in_vop))
            end
          else
            block.call(encode_packet(av_packet, ssrc, true))
          end
          @encode_queue.pop(&processor)
        end
        @encode_queue.pop(&processor)
      end

      def timestamp
        @timestamp += send_frequency
      end

      def sequence_number
        @sequence_number = if @sequence_number
          @sequence_number + 1
        else
          rand(4294967295)
        end
      end

      private

      def encode_packet(av_packet, ssrc, last_in_vop)
        rtp_packet = RTP::Packet.new
        rtp_packet.version        = 2
        rtp_packet.marker         = last_in_vop ? 1 : 0
        rtp_packet.payload_type   = 96
        rtp_packet.sequence_number = sequence_number
        rtp_packet.timestamp      = timestamp.to_i
        rtp_packet.ssrc_id        = ssrc
        rtp_packet.payload        = av_packet

        rtp_packet
      end
    end
  end
end