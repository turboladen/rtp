require 'socket'
#require_relative 'senders/socat'
#require 'singleton'


module RTP
  class Sender
    #include Singleton

    attr_accessor :port
    attr_accessor :ip
    attr_reader :ssrc
    attr_reader :socket_type

    #def initialize(type)
    def initialize(protocol, port, ip=nil)
      #@stream_module = if type == :socat
      #  self.class.send(:include, RTP::Senders::Socat)
      #end
      if protocol == :UDP
        socket = UDPSocket.open
      end

      #@sessions = {}
      #@pids = {}
      #@rtcp_threads = {}
      #@rtp_timestamp = 2612015746
      #@rtp_sequence = 21934
      #@rtp_map = []
      #@fmtp = []
      #@source_ip = []
      #@source_port = []

      @ssrc = rand(4294967295)
      @socket_type = :UDP
    end

    def socket_type=(type)
      @socket_type = type.upcase.to_sym
    end

    #def send(start_time, stop_time)
    #end

    # Sets the stream module to be used by the stream server.
    #
    # @param [Module] module_name Module name.
    #def stream_module=(module_name)
    #  @stream_module = module_name
    #  self.class.send(:include, module_name)
    #end

    # Gets the current stream_module.
    #
    # @return [Module] Module name.
    #def stream_module
    #  @stream_module
    #end
  end
end
