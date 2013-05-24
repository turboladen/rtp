require 'eventmachine'
require 'pants'
require_relative 'logger'


module RTP
  class RTPSenderConnection < EM::Connection

  end

  class Sender
    def initialize(source_file, destination_uri)
      @pants = Pants.new
      @pants.add_demuxer(source_file, :video)

      # Must start with rtp://
      @pants.add_writer(destination_uri)
    end

    def start
      @pants.run
    end
  end
end

Pants.writers << { uri_scheme: 'rtp', klass: RTP::Sender }
