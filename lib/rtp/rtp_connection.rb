require 'tempfile'
require 'eventmachine'

require_relative 'packet'
require_relative 'logger'


module RTP
  class RTPConnection < EM::Connection
    include LogSwitch::Mixin

    DEFAULT_CAPFILE_NAME = 'rtp_capture.raw'

    # @param [Fixnum] ssrc The synchronization source ID that identifies the
    #   participant in a session that's using this connection.
    # @param [EventMachine::Callback] receive_callback The callback that should
    #   get called when RTP packets are received.
    # @param [Boolean] strip_headers If set to true, RTP headers will
    #   be stripped from packets before they're passed on to the callback.
    def initialize(ssrc, receive_callback: nil,
      strip_headers: false, capture_file: Tempfile.new(DEFAULT_CAPFILE_NAME)
      )
      @ssrc = ssrc
      @receive_callback = receive_callback
      @strip_headers = strip_headers
      @capture_file = capture_file

      log "RTPConnection initialized with ssrc #{@ssrc}"

      at_exit do
        unless @capture_file.closed?
          log 'Closing and deleting capture capture file...'
          @capture_file.close
          @capture_file.unlink
        end
      end
    end

    # Receives data on the socket, parses it as an RTP::Packet, strips headers
    # (if set to do so), then yields the Packet to the callback that was given
    # at init.
    def receive_data(data)
      log "Got RTP data, size: #{data.size}"

      packet = Packet.read(data)
      data_to_write = @strip_headers ? packet.rtp_payload : packet

      @receive_callback.call(data_to_write)
    end
  end
end
