require 'tempfile'
require 'socket'
require 'timeout'

require_relative 'logger'
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
    include LogSwitch::Mixin

    # Name of the file the data will be captured to unless #rtp_file is set.
    DEFAULT_CAPFILE_NAME = "rtp_capture.raw"

    # Maximum number of bytes to receive on the socket.
    MAX_BYTES_TO_RECEIVE = 1500

    # Maximum times to retry using the next greatest port number.
    MAX_PORT_NUMBER_RETRIES = 50

    # @param [File] rtp_file The file to capture the RTP data to.
    # @return [File]
    attr_accessor :rtp_file

    # @param [Boolean] strip_headers True if you want to strip the RTP headers.
    attr_accessor :strip_headers

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
      @packet_writer = nil
      @packets = Queue.new
      @strip_headers = false
    end

    # Initializes a server of the correct socket type.
    #
    # @return [UDPSocket, TCPSocket]
    # @raise [RTP::Error] If +@transport_protocol was not set to +:UDP+ or
    #   +:TCP+.
    def init_server(protocol, port=9000)
      port_retries = 0

      begin
        if protocol == :UDP
          server = UDPSocket.open
          server.bind('0.0.0.0', port)
        elsif protocol == :TCP
          server = TCPServer.new(port)
        else
          raise RTP::Error,
            "Unknown streaming_protocol requested: #{@transport_protocol}"
        end

        set_socket_time_options(server)
      rescue Errno::EADDRINUSE, SocketError
        log "RTP port #{port} in use, trying #{port + 2}..."
        port += 2
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      @rtp_port = port
      log "TCP server setup to receive on port #{@rtp_port}"

      server
    end

    # Starts the +@listener+ thread that starts up the server, then takes the
    # data received from the server and pushes it on to +@packets+.
    #
    # If a block is given, this will yield each parsed packet as an RTP::Packet.
    #
    # @return [Thread] The listener thread (+@listener+).
    # @yield [RTP::Packet] Each parsed packet that comes in over the wire.
    def run(&block)
      log "Starting #{self.class} on port #{@rtp_port}..."
      return @listener if listening?

      @packet_writer = start_packet_writer
      @packet_writer.abort_on_exception = true

      @listener = start_listener(&block)
      @listener.abort_on_exception = true
    end

    def start_listener
      Thread.start do
        server = init_server(@transport_protocol, @rtp_port)

        loop do
          msg = server.recvmsg(MAX_BYTES_TO_RECEIVE)
          data = msg.first
          log "Received data at size: #{data.size}"

          log "RTP timestamp from socket info: #{msg.last.timestamp}"
          @packet_timestamps << msg.last.timestamp

          packet = RTP::Packet.read(data)
          @packets << packet

          yield packet if block_given?
        end
      end
    end

    # Stops the listener and packet writer threads.
    def stop
      log "Stopping #{self.class} on port #{@rtp_port}..."
      stop_listener
      log "listening? #{listening?}"

      stop_packet_writer
      log "writing packets? #{writing_packets?}"
      log "running? #{running?}"
    end

    # @return [Boolean] true if the +@listener+ thread is running; false if not.
    def listening?
      !@listener.nil? ? @listener.alive? : false
    end

    # @return [Boolean] true if ready to write packets to file.
    def writing_packets?
      !@packet_writer.nil? ? @packet_writer.alive? : false
    end

    # Returns if the #run loop is in action.
    #
    # @return [Boolean] true if the run loop is running.
    def running?
      listening? && writing_packets?
    end

    private

    # Writes all packets on the @packets Queue to the +@rtp_file+.  If
    #+ @strip_headers+ is set, it only writes the RTP payload to the file.
    def start_packet_writer
      packets = []

      # If a block is given for packet inspection, perhaps we should save
      # some I/O ano not write the packet to file?
      Thread.start do
        loop do
          packets << @packets.pop

          packets.each do |packet|
            if @strip_headers
              @rtp_file.write packet['rtp_payload']
            else
              @rtp_file.write packet
            end
          end
        end
      end
    end

    # Kills the +@listener+ thread and sets the variable to nil.
    def stop_listener
      log "Stopping listener..."
      @listener.kill if listening?
      @listener = nil
      log "Listener stopped."
    end

    # Waits for all packets to be written out before killing.  If after 10
    # seconds,
    def stop_packet_writer
      log "Stopping packet writer..."
      wait_for = 10

      begin
        timeout(wait_for) do
          sleep 0.2 until @packets.empty?
        end
      rescue Timeout::Error
        log "Packet buffer not empty after #{wait_for} seconds.  Trying to stop listener..."
        stop_listener
      end

      @packet_writer.kill if writing_packets?
      @packet_writer = nil
      log "Packet writer stopped."
    end

    # Sets SO_TIMESTAMP socket option to true.  Sets SO_RCVTIMEO to 2.
    #
    # @param [Socket] socket The Socket to set options on.
    # @return [Socket] The socket with the options set.
    def set_socket_time_options(socket)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_TIMESTAMP, true)
      optval = [0, 1].pack("l_2")
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval)

      socket
    end
  end
end
