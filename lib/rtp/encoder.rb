require_relative '../ext/uri_rtp'
require 'pants'
require_relative 'logger'
require_relative 'packet'
Dir[File.dirname(__FILE__) + "/encoders/*.rb"].each { |f| require f }


module RTP
  class Encoder < Pants::Seam
    include LogSwitch::Mixin

    ENCODERS = {
      mpeg4: RTP::Encoders::MPEG4
    }

    def initialize(main_callback, write_to_channel, codec_id, frame_rate)
      @send_queue = EM::Queue.new
      start_sending

      # For now, define here...
      @ssrc = rand(4294967295)

      log "Codec ID: #{codec_id}"
      log "Frame rate: #{frame_rate}"
      @encoder = ENCODERS[codec_id].new(frame_rate)

      super(main_callback, write_to_channel)
    end

    def stop
      log "Finishing ID #{__id__}"

      super
    end

    def start
      callback = EM.Callback do
        log "#{__id__} Adding a #{self.class}..."
        read do |av_packet|
          encode(av_packet)
        end
      end

      super(callback)
    end

    def encode(av_packet)
      #rtp_packet = @encoder.encode(av_packet, @ssrc)
      #log "Encoded packet payload size: #{rtp_packet.payload.size}"
      #write(rtp_packet.to_binary_s)
      EM.defer do
        @encoder.encode(av_packet, @ssrc) do |rtp_packet|
          log "Encoded packet payload size: #{rtp_packet.payload.size}"
          #write(rtp_packet.to_binary_s)
          @send_queue << rtp_packet.to_binary_s
        end
      end
    end

    def start_sending
      processor = proc do |item|
        EM.add_timer(@encoder.send_frequency) do
          write(item)
        end

        @send_queue.pop(&processor)
      end

      @send_queue.pop(&processor)
    end
  end
end

Pants.writers << {
  uri_scheme: :rtp_encoder,
  klass: RTP::Encoder,
  args: [:codec_id, :frame_rate]
}
