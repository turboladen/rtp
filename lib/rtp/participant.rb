require_relative 'session'


module RTP
  class Participant
    attr_reader :sessions

    def initialize
      @sessions = []
    end

    # Joins a RTP Session that's defined by the given RTP/RTCP IP and port and
    # adds that session to the list of sessions that it's participating in.
    # Allows for passing a block that will get called when RTP packets are
    # received, thus allowing you to specify what to do with the packet (i.e.
    # write it to file, inspect it, etc.).
    #
    # @param [String] ip
    # @param [Fixnum] rtp_port
    # @param [Fixnum] rtcp_port
    # @param [EventMachine::Callback] rtcp_callback
    #
    # @return [RTP::Session]
    def join_session(ip, rtp_port, rtcp_port: rtp_port+1, rtcp_callback: nil, &rtp_callback)
      ssrc = rand(4294967295)
      session = RTP::Session.new(ssrc, ip, rtp_port, rtcp_port, rtcp_callback, &rtp_callback)

      @sessions << session
      starter = proc { session.start }

      if EM.reactor_running?
        starter.call
      else
        EM.run { starter.call }
      end

      session
    end
  end
end
