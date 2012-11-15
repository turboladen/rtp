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

    MULTICAST_TTL = 4

    # @return [File] The file to capture the RTP data to.
    attr_reader :capture_file

    # @return [Array<Time>] The packet receipt timestamps.
    attr_reader :packet_timestamps

    # @return [Fixnum] The port on which to capture RTP data.
    attr_reader :rtp_port

    # @return [Fixnum] rtcp_port Added for clarifying the roles of ports; not
    #   currently used though.
    attr_reader :rtcp_port

    # @return [Symbol] The type of socket to use for capturing the RTP data.
    #   +:UDP+ or +:TCP+.
    attr_accessor :transport_protocol

    # @return [Symbol] The IP addressing type to use for capturing the data.
    #   +:multicast+ or +:unicast:.
    attr_accessor :ip_addressing_type

    # @param [Hash] options
    # @option [Symbol] :transport_protocol The type of socket to use for capturing
    #   the data. +:UDP+ or +:TCP+.
    # @option [Symbol] :ip_addressing_type The IP addressing type to use for
    #   capturing the data.  +:multicast+ or +:unicast:.
    # @option [String] :multicast_address The multicast address to listen on.
    #   Only required if the +:ip_addressing_type+ type is set to +:multicast+.
    # @option [Fixnum] :rtp_port The port on which to capture RTP data.
    #   #rtcp_port will be set to the next port above this.
    # @option [Boolean] :strip_headers
    # @option [File] :capture_file The file object to capture the RTP data to.
    def initialize(options={})
      @transport_protocol = options[:transport_protocol]  || :UDP
      @ip_addressing_type = options[:ip_addressing_type]  || :unicast
      @multicast_address  = options[:multicast_address]
      @rtp_port           = options[:rtp_port]            || 9000
      @rtcp_port          = @rtp_port + 1
      @strip_headers      = options[:strip_headers]       || false
      @capture_file = options[:capture_file] || Tempfile.new(DEFAULT_CAPFILE_NAME)

      @listener = nil
      @packet_writer = nil
      @packets = Queue.new
      @packet_timestamps = []
    end

    # Starts the packet writer (buffer) and listener.
    #
    # If a block is given, this will yield each parsed packet as an RTP::Packet.
    # This lets you inspect packets as they come in:
    # @example
    #   RTP::Receiver.new
    #   receiver.start do |packet|
    #     puts packet["sequence_number"]
    #   end
    def start(&block)
      return if running?
      log "Starting receiving on port #{@rtp_port}..."

      @packet_writer = start_packet_writer
      @packet_writer.abort_on_exception = true

      server = init_socket(@transport_protocol, @rtp_port, @ip_addressing_type)

      @listener = start_listener(server, &block)
      @listener.abort_on_exception = true
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

    # @return [Boolean] true if the listener thread is running; false if not.
    def listening?
      !@listener.nil? ? @listener.alive? : false
    end

    # @return [Boolean] true if ready to write packets to file.
    def writing_packets?
      !@packet_writer.nil? ? @packet_writer.alive? : false
    end

    # @return [Boolean] true if the Receiver is listening and writing packets.
    def running?
      listening? && writing_packets?
    end

    # Updates the rtp_port and sets the rtcp_port to be this +1.
    def rtp_port=(port)
      @rtp_port = port
      @rtcp_port = @rtp_port + 1
    end

    private

    # Writes all packets on the @packets Queue to the +@capture_file+.  If
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
              @capture_file.write packet['rtp_payload']
            else
              @capture_file.write packet
            end
          end
        end
      end
    end

    # Initializes a socket of the requested type.
    #
    # @return [UDPSocket, TCPServer]
    # @raise [RTP::Error] If +@transport_protocol was not set to +:UDP+ or
    #   +:TCP+.
    def init_socket(protocol, port, ip_addressing_type, multicast_address=nil)
      port_retries = 0

      begin
        if protocol == :UDP
          socket = UDPSocket.open
          socket.bind('0.0.0.0', port)
        elsif protocol == :TCP
          socket = TCPServer.new('0.0.0.0', port)
        else
          raise RTP::Error,
            "Unknown streaming_protocol requested: #{protocol}"
        end

        set_socket_time_options(socket)
      rescue Errno::EADDRINUSE, SocketError
        log "RTP port #{port} in use, trying #{port + 2}..."
        port += 2
        port_retries += 1
        retry until port_retries == MAX_PORT_NUMBER_RETRIES + 1
        port = 9000
        raise
      end

      if ip_addressing_type == :multicast
        unless multicast_address
          raise RTP::Error,
            "ip_addressing_type set to :multicast, but no multicast address given."
        end

        setup_multicast_socket(socket, multicast_address)
      end

      @rtp_port = port
      log "#{protocol} server setup to receive on port #{@rtp_port}"

      socket
    end

    # Starts the thread that receives the RTP data, then takes that data and
    # pushes it on to +@packets+ for processing.
    #
    # If a block is given, this will yield each parsed packet as an RTP::Packet.
    #
    # @param [IPSocket] socket The socket to listen on.
    # @yield [RTP::Packet] Each parsed packet that comes in over the wire.
    def start_listener(socket)
      Thread.start(socket) do
        loop do
          msg = socket.recvmsg(MAX_BYTES_TO_RECEIVE)
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
    end

    # Sets Socket options to allow for multicasting.  If ENV["RUBY_UPNP_ENV"] is
    # equal to "testing", then it doesn't turn off multicast looping.
    def setup_multicast_socket(socket, multicast_address)
      set_membership(socket,
        IPAddr.new(multicast_address).hton + IPAddr.new('0.0.0.0').hton)
      set_multicast_ttl(socket, MULTICAST_TTL)
      set_ttl(socket, MULTICAST_TTL)
    end

    # @param [String] membership The network byte ordered String that represents
    #   the IP(s) that should join the membership group.
    def set_membership(socket, membership)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    end

    # @param [Fixnum] ttl TTL to set IP_MULTICAST_TTL to.
    def set_multicast_ttl(socket, ttl)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, [ttl].pack('i'))
    end

    # @param [Fixnum] ttl TTL to set IP_TTL to.
    def set_ttl(socket, ttl)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, [ttl].pack('i'))
    end
  end
end
