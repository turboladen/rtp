require 'tempfile'
require 'socket'

require_relative '../rtp'
require_relative 'error'
require_relative 'packet'

module RTP

  # Objects of this type can be used with a +RTSP::Client+ object in order to
  # capture the RTP data transmitted to the client as a result of an RTSP
  # PLAY call.
  #
  # In this version, objects of this type don't do much other than just capture
  # the data to a file; in later versions, objects of this type will be able
  # to provide a "sink" and allow for ensuring that the received  RTP packets
  # will be reassembled in the correct order, as they're written to file
  # (objects of this type don't don't currently allow for checking RTP sequence
  # numbers on the data that's been received).
  class Receiver

    # Name of the file the data will be captured to unless {#rtp_file} is set.
    DEFAULT_CAPFILE_NAME = "rtp_capture.raw"

    # Maximum number of bytes to receive on the socket.
    MAX_BYTES_TO_RECEIVE = 1500

    # Maximum times to retry using the next greatest port number.
    MAX_PORT_NUMBER_RETRIES = 50

    # @param [File] rtp_file The file to capture the RTP data to.
    # @return [File]
    attr_accessor :rtp_file

    # @return [Array<Time>] packet_timestamps The packet receipt timestamps.
    attr_accessor :packet_timestamps
    
    # @param [Fixnum] rtp_port The port on which to capture the RTP data.
    # @return [Fixnum]
    attr_accessor :rtp_port

    # @param [Symbol] transport_protocol +:UDP+ or +:TCP+.
    # @return [Symbol]
    attr_accessor :transport_protocol

    # @param [Symbol] broadcast_type +:multicast+ or +:unicast+.
    # @return [Symbol]
    attr_accessor :broadcast_type

    # @param [Symbol] transport_protocol The type of socket to use for capturing
    #   the data. +:UDP+ or +:TCP+.
    # @param [Fixnum] rtp_port The port on which to capture RTP data.
    # @param [File] rtp_capture_file The file object to capture the RTP data to.
    def initialize(transport_protocol=:UDP, rtp_port=9000, rtp_capture_file=nil)
      @transport_protocol = transport_protocol
      @rtp_port = rtp_port
      @rtp_file = rtp_capture_file || Tempfile.new(DEFAULT_CAPFILE_NAME)
      @packet_timestamps = []
      @listener = nil
      @file_builder = nil
      @write_to_file_queue = Queue.new
    end

    # Initializes a server of the correct socket type.
    #
    # @return [UDPSocket, TCPSocket]
    # @raise [RTP::Error] If +@transport_protocol was not set to +:UDP+ or
    #   +:TCP+.
    def init_server(protocol, port=9000)
      if protocol == :UDP
        server = init_udp_server(port)
      elsif protocol == :TCP
        server = init_tcp_server(port)
      else
        raise RTP::Error, "Unknown streaming_protocol requested: #{@transport_protocol}"
      end

      server
    end

    # Simply calls {#start_file_builder} and {#start_listener}.
    def run
      RTP.log "Starting #{self.class} on port #{@rtp_port}..."

      start_file_builder
      start_listener
    end

    # Starts the +@file_builder+ thread that pops data off of the Queue that
    # {#start_listener} pushed data on to.  It then takes that data and writes it
    # to +@rtp_file+.
    #
    # @return [Thread] The file_builder thread (+@file_builder+).
    def start_file_builder
      return @file_builder if file_building?

      @file_builder = Thread.start(@rtp_file) do |rtp_file|
        loop do
          rtp_file.write @write_to_file_queue.pop["rtp_payload"] until @write_to_file_queue.empty?
        end
      end

      @file_builder.abort_on_exception = true
    end

    # Starts the +@listener+ thread that starts up the server, then takes the
    # data received from the server and pushes it on to the +@write_to_file_queue+ so
    # the +@file_builder+ thread can deal with it.
    #
    # @return [Thread] The listener thread (+@listener+).
    def start_listener
      return @listener if @listener and @listener.alive?

      @listener = Thread.start do
        server = init_server(@transport_protocol, @rtp_port)

        loop do
          msg = server.recvmsg(MAX_BYTES_TO_RECEIVE)
          data = msg.first
          timestamp = msg.last.timestamp
          @packet_timestamps << timestamp
          RTP.log "Received timestamped packet '#{timestamp}' with size '#{data.size}'"
          packet = RTP::Packet.read(data)
          RTP.log "RTP payload size: #{packet["rtp_payload"].size}"
          @write_to_file_queue << packet
        end
      end

      @listener.abort_on_exception = true
    end

    # @return [Boolean] true if the +@listener+ thread is running; false if not.
    def listening?
      !@listener.nil? ? @listener.alive? : false
    end

    # @return [Boolean] true if the +@file_builder+ thread is running; false if
    #   not.
    def file_building?
      !@file_builder.nil? ? @file_builder.alive? : false
    end

    # Returns if the {#run} loop is in action.
    #
    # @return [Boolean] true if the run loop is running.
    def running?
      listening? || file_building?
    end

    # Breaks out of the run loop.
    def stop
      RTP.log "Stopping #{self.class} on port #{@rtp_port}..."
      stop_listener
      RTP.log "listening? #{listening?}"
      stop_file_builder
      RTP.log "file building? #{file_building?}"
      RTP.log "running? #{running?}"
      @write_to_file_queue = Queue.new
    end

    # Kills the +@listener+ thread and sets the variable to nil.
    def stop_listener
      @listener.kill if @listener
      @listener = nil
    end

    # If the object from self is still listening, this kills +@file_builder+,
    # otherwise this waits for the +@write_to_file_queue+
    # to be empty (i.e. it has written out the queued up data).
    def stop_file_builder
      if file_building?
        @file_builder.kill
      end

      @file_builder = nil
    end

    # Sets up to receive data on a UDP socket, using +@rtp_port+.
    #
    # @param [Fixnum] port Port number to listen for RTP data on.
    # @return [UDPSocket]
    def init_udp_server(port)
      port_retries = 0

      begin
        server = UDPSocket.open
        server.bind('0.0.0.0', port)
        server.setsockopt(:SOCKET, :TIMESTAMP, true)
      rescue Errno::EADDRINUSE
        RTP.log "RTP port #{port} in use, trying #{port + 1}..."
        port += 1
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      @rtp_port = port
      RTP.log "UDP server setup to receive on port #{@rtp_port}"

      server
    end

    # Sets up to receive data on a TCP socket, using +@rtp_port+.
    #
    # @param [Fixnum] port Port number to listen for RTP data on.
    # @return [TCPServer]
    def init_tcp_server(port)
      port_retries = 0

      begin
        server = TCPServer.new(port)
        server.setsockopt(:SOCKET, :TIMESTAMP, true)
      rescue Errno::EADDRINUSE
        RTP.log "RTP port #{port} in use, trying #{port + 1}..."
        port += 1
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      @rtp_port = port
      RTP.log "TCP server setup to receive on port #{@rtp_port}"

      server
    end
  end
end
