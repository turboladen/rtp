require 'eventmachine'


module RTP
  class RTPConnection < EM::Connection
    def initialize(ssrc)
      @ssrc = ssrc
      puts "RTPConnection initialized with ssrc #{@ssrc}"
    end

    def receive_data data
      puts "Got RTP data, size: #{data.size}"
    end
  end
end
