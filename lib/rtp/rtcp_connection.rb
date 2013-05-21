require 'eventmachine'
require_relative 'rtcp_packet'


module RTP
  class RTCPConnection < EM::Connection
    def receive_data data
      puts "Got RTCP data, size: #{data.size}"

      packet = RTCPPacket.read(data)

      p packet

      packet
    end
  end
end
