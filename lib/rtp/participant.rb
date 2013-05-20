require_relative 'session'


module RTP
  class Participant
    attr_reader :sessions

    def initialize
      @sessions = []
    end

    # Joins a RTP Session that's defined by the given RTP/RTCP IP and port and
    # adds that session to the list of sessions that it's participating in.
    #
    # @param [String] ip
    # @param [Fixnum] rtp_port
    # @param [Fixnum] rtcp_port
    #
    # @return [RTP::Session]
    def join_session(ip, rtp_port, rtcp_port=rtp_port+1)
      ssrc = rand(4294967295)
      session = RTP::Session.new(ssrc, ip, rtp_port, rtcp_port)

      @sessions << session

      session
    end
  end
end
