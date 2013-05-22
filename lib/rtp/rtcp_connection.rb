require 'eventmachine'
require 'socket'
require 'ipaddr'

require_relative 'connection'
require_relative 'rtcp_packet'
require_relative 'logger'


module RTP
  class RTCPConnection < Connection
    include LogSwitch::Mixin

    # @param [EventMachine::Callback] callback The callback to call when a
    #   packet is received and parsed.
    def initialize(callback=nil)
      @callback = callback

      ip, _ = self_info
      setup_multicast_socket(ip) if multicast?(ip)
    end

    # Receives packets and parses them.  If a callback was given on init,
    # that gets called with the parsed packet (a {RTP::RTCPPacket}).
    #
    # @param [String] data
    def receive_data data
      log "Got RTCP data, size: #{data.size}"

      packet = RTCPPacket.read(data)

      if @callback
        @callback.call(packet)
      else
        packet
      end
    end
  end
end
