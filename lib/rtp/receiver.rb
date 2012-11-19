require 'tempfile'
require 'socket'
require 'timeout'

require_relative 'logger'
require_relative 'error'
require_relative 'packet'


module RTP

  # Objects of this type receive RTP data over a socket and either save them to
  # a file, or yield the packets to a given block.  This is useful with other
  # protocols, like RTSP.
  #
  # @example Save to file
  #
  #   receiver = RTP::Receiver.new      # Uses a Tempfile by default
  #   receiver.rtp_port                 # => 6790
  #   receiver.transport_protocol       # => :UDP
  #   receiver.multicast?               # => false
  #   receiver.unicast?                 # => true
  #   receiver.start
  #   sleep 5
  #   receiver.stop
  #   receiver.capture_file.size        # => 2004
  #
  # @example Save to user-created file, with some other options
  #
  #   options = {
  #     transport_protocol: :TCP,
  #     ip_address: '239.255.255.250', # Multicast!
  #     strip_headers: true,           # Strips RTP headers before writing to file
  #     capture_file: File.new('data.rtp', 'wb')
  #   }
  #
  #   receiver = RTP::Receiver.new(9000, options) # Receive on port 9000
  #   receiver.start
  #   sleep 5
  #   receiver.stop
  #   receiver.capture_file.size        # => 1884
  #
  # @example Yield packets
  #
  #   receiver = RTP::Receiver.new
  #   receiver.start do |packet|
  #     puts "Sequence number: #{packet['sequence_number']}"  # => Sequence number: 2931830
  #   end
  #   sleep 5
  #   receiver.stop
  #   receiver.capture_file.size        # => 0
  #
  class Receiver
    include LogSwitch::Mixin

    # Name of the file the data will be captured to unless #rtp_file is set.
    DEFAULT_CAPFILE_NAME = "rtp_capture.raw"

    # Maximum number of bytes to receive on the socket.
    MAX_BYTES_TO_RECEIVE = 1500

    # TTL value that will be used if receiving on a multicast socket.
    MULTICAST_TTL = 4

    # @return [File] The file to capture the RTP data to.
    attr_reader :capture_file

    # @return [Array<Time>] The packet receipt timestamps.
    attr_reader :packet_timestamps

    # @return [Fixnum] The port on which to capture RTP data.
    attr_reader :rtp_port

    # @return [Fixnum] Added for clarifying the roles of ports; not
    #   currently used though.
    attr_reader :rtcp_port

    # @return [Symbol] The type of socket to use for capturing the RTP data.
    #   +:UDP+ or +:TCP+.
    attr_accessor :transport_protocol

    # @return [String] The IP address to receive RTP data on.
    attr_accessor :ip_address

    # @param [Fixnum] rtp_port The port on which to capture RTP data.
    #   +rtcp_port+ will be set to the next port above this.
    #
    # @param [Hash] options
    # @option options [Symbol] :transport_protocol The type of socket to use for
    #   capturing the data. +:UDP+ or +:TCP+.
    # @option options [String] :ip_address The IP address to open the socket on.
    #   If this is a multicast address, multicast options will be set.
    # @option options [Boolean] :strip_headers If set to true, RTP headers will
    #   be stripped from packets before they're written to the capture file.
    # @option options [File] :capture_file The file object to capture the RTP
    #   data to.
    def initialize(rtp_port=6970, options={})
      @rtp_port           = rtp_port
      @rtcp_port          = @rtp_port + 1

      @transport_protocol = options[:transport_protocol]  || :UDP
      @ip_address         = options[:ip_address]          || '0.0.0.0'
      @strip_headers      = options[:strip_headers]       || false
      @capture_file       = options[:capture_file]        ||
        Tempfile.new(DEFAULT_CAPFILE_NAME)

      at_exit do
        if @capture_file.closed?
          puts "Capture file already closed."
        else
          puts "Closing and deleting capture capture file..."
          @capture_file.close
          @capture_file.unlink
        end
      end

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
    #   receiver = RTP::Receiver.new
    #   receiver.start do |packet|
    #     puts packet["sequence_number"]
    #   end
    #
    # @yield [RTP::Packet] Each parsed packet that comes in over the wire.
    #
    # @return [Boolean] true if started sucessfully.
    def start(&block)
      return if running?
      log "Starting receiving on port #{@rtp_port}..."

      @packet_writer = start_packet_writer
      @packet_writer.abort_on_exception = true

      server = init_socket(@transport_protocol, @rtp_port, @ip_address)

      @listener = start_listener(server, &block)
      @listener.abort_on_exception = true

      running?
    end

    # Stops the listener and packet writer threads.
    #
    # @return [Boolean] true if stopped sucessfully.
    def stop
      log "Stopping #{self.class} on port #{@rtp_port}..."
      stop_listener
      log "listening? #{listening?}"

      stop_packet_writer
      log "writing packets? #{writing_packets?}"
      log "running? #{running?}"

      !running?
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

    # @return [Boolean] true if +ip_address+ is a multicast address or not.
    def multicast?
      first_octet = @ip_address.match(/^(\d\d\d?)/).to_s.to_i
      first_octet >= 224 && first_octet <= 239
    end

    # @return [Boolean] true if +ip_address+ is a unicast address or not.
    def unicast?
      !multicast?
    end

    # @return [Symbol] The IP addressing type to use for capturing the data.
    #   +:multicast+ or +:unicast:.
    def ip_addressing_type
      multicast? ? :multicast : :unicast
    end

    private

    # Writes all received packets (in the @packets Queue} to the +capture_file+.
    # If +strip_headers+ is set, it only writes the RTP payload to the file.
    #
    # @return [Thread] The packet writer thread.
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
    # @param [Symbol] protocol The protocol on which to receive RTP data.
    # @param [Fixnum] port The port on which to receive RTP data.
    # @param [String] ip_address The IP on which to receive RTP data.
    # @return [UDPSocket, TCPServer]
    # @raise [RTP::Error] If +protocol+ was not set to +:UDP+ or +:TCP+.
    def init_socket(protocol, port, ip_address)
      if protocol == :UDP
        socket = UDPSocket.open
        socket.bind(ip_address, port)
      elsif protocol == :TCP
        socket = TCPServer.new(ip_address, port)
      else
        raise RTP::Error,
          "Unknown protocol requested: #{protocol}.  Options are :TCP or :UDP"
      end

      set_socket_time_options(socket)
      setup_multicast_socket(socket, multicast_address) if multicast?

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
    # @return [Thread] The listener thread.
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
    #
    # @return [Boolean] true if it stopped listening.
    def stop_listener
      log "Stopping listener..."
      @listener.kill if listening?
      @listener = nil
      log "Listener stopped."

      !listening?
    end

    # Waits for all packets to be written out before killing.  AFter 10 seconds
    # it'll force close the writer.
    #
    # @return [Boolean] true if it stopped the packet writer.
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

      @capture_file.close

      !writing_packets?
    end

    # Sets SO_TIMESTAMP socket option to true.  Sets SO_RCVTIMEO to 2.
    #
    # @param [Socket] socket The Socket to set options on.
    def set_socket_time_options(socket)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_TIMESTAMP, true)
      optval = [0, 1].pack("l_2")
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval)
    end

    # Sets Socket options to allow for multicasting.  If ENV["RUBY_UPNP_ENV"] is
    # equal to "testing", then it doesn't turn off multicast looping.
    #
    # @param [Socket] socket The socket to set the options on.
    # @param [String] multicast_address The IP address to set the options on.
    def setup_multicast_socket(socket, multicast_address)
      set_membership(socket,
        IPAddr.new(multicast_address).hton + IPAddr.new('0.0.0.0').hton)
      set_multicast_ttl(socket, MULTICAST_TTL)
      set_ttl(socket, MULTICAST_TTL)
    end

    # @param [Socket] socket The socket to set the options on.
    # @param [String] membership The network byte ordered String that represents
    #   the IP(s) that should join the membership group.
    def set_membership(socket, membership)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    end

    # @param [Socket] socket The socket to set the options on.
    # @param [Fixnum] ttl TTL to set IP_MULTICAST_TTL to.
    def set_multicast_ttl(socket, ttl)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, [ttl].pack('i'))
    end

    # @param [Socket] socket The socket to set the options on.
    # @param [Fixnum] ttl TTL to set IP_TTL to.
    def set_ttl(socket, ttl)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, [ttl].pack('i'))
    end
  end
end
