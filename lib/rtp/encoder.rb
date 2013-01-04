require_relative '../ext/uri_rtp'
require 'pants'
require_relative 'logger'


module RTP
  class Encoder < Pants::BaseWriter
    include LogSwitch::Mixin

    def initialize(read_from_channel)
      @tee = Pants::Tee.new

      @starter = proc do
        log "#{__id__} Adding a #{self.class}..."
        @tee.start

        EM.defer do
          read_from_channel.subscribe do |packet|
            encoded_packet = encode(packet)
            @tee.write_to_channel << encoded_packet
          end
        end
      end

      @finisher = proc do
        log "Finishing ID #{__id__}"
        @tee.finisher.set_deferred_success
      end

      super()
    end

    def encode(packet)
      packet
    end

    def tee(&block)
      if block
        block.call(@tee)
      end

      @tee
    end
  end
end

Pants.writers << { uri_scheme: :rtp_encoder, klass: RTP::Encoder }
