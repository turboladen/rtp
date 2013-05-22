require 'tempfile'
require 'eventmachine'

require_relative 'connection'
require_relative 'encoder'
require_relative 'rtp_packet'
require_relative 'logger'


module RTP
  class RTPConnection < Connection
    include LogSwitch::Mixin

    DEFAULT_CAPFILE_NAME = 'rtp_capture.raw'

    # @param [Fixnum] ssrc The synchronization source ID that identifies the
    #   participant in a session that's using this connection.
    # @param [EventMachine::Callback,Proc] receiver The callback that should
    #   get called when RTP packets are received.  Can be any object that
    #   responds to #call and takes a RTP::RTPPacket.
    # @param [Boolean] strip_headers If set to true, RTP headers will
    #   be stripped from packets before they're passed on to the callback.
    def initialize(ssrc, receiver, sender,
      strip_headers: false,
      capture_file: Tempfile.new(DEFAULT_CAPFILE_NAME)
      )
      @ssrc = ssrc
      @sender = sender
      @receiver = receiver
      @strip_headers = strip_headers
      @capture_file = capture_file

      ip, _ = self_info
      setup_multicast_socket(ip) if multicast?(ip)

      log "RTPConnection initialized with ssrc #{@ssrc}"

      at_exit do
        unless @capture_file.closed?
          log 'Closing and deleting capture capture file...'
          @capture_file.close
          @capture_file.unlink
        end
      end
    end

    # Receives data on the socket, parses it as an RTP::RTPPacket, strips headers
    # (if set to do so), then yields the RTPPacket to the callback that was given
    # at init.
    def receive_data(data)
      log "Got RTP data, size: #{data.size}"

      packet = RTPPacket.read(data)
      data_to_write = @strip_headers ? packet.rtp_payload : packet

      if @receiver
        @receiver.call(data_to_write)
      else
        data_to_write
      end
    end
  end
end
