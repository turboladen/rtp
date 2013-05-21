require 'tempfile'
require 'eventmachine'

require_relative 'packet'
require_relative 'logger'


module RTP
  class RTPConnection < EM::Connection
    include LogSwitch::Mixin

    DEFAULT_CAPFILE_NAME = 'rtp_capture.raw'

    def initialize(ssrc, receive_callback,
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

    def receive_data(data)
      log "Got RTP data, size: #{data.size}"

      packet = Packet.read(data)
      data_to_write = @strip_headers ? packet.rtp_payload : packet

      @receive_callback.call(data_to_write)
    end
  end
end
