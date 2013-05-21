require 'eventmachine'


module RTP
  class RTCPConnection < EM::Connection
    def receive_data data
      puts "Got RTCP data, size: #{data.size}"
    end
  end
end
