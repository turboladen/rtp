require_relative 'logger'
require_relative 'rtp_packet'
require_relative 'sender'


=begin
class IOWriter
  def initialize(destination_ip, destination_port)
    @ip = destination_ip
    @port = destination_port
    @writer = UDPSocket.open
  end

  def write(data)
    puts "WRITER: sending data to #{@ip}:#{@port} with size: #{data.size}"
    #puts "WRITER: 50th byte: #{data[50]}"

    @writer.send(data, 0, @ip, @port)
  end
end
=end

module RTP
  # A Server is responsible for sending RTP transport data and RTCP control
  # data.
  class Server
    include LogSwitch::Mixin

    #attr_reader :rtp_sender
    #attr_reader :rtcp_sender

    # @param [Hash] writer_settings
    def initialize(writer_settings)
      @writer_protocol = writer_settings[:protocol] || :UDP
      @writer_ip = writer_settings[:ip]
      @writer_port = writer_settings[:port]
      @writer_socket = nil
      @writer_thread = nil

      @ssrc = rand(4294967295)

      @packets = Queue.new
    end

    def start
      @writer_socket = init_socket(@writer_protocol, @writer_port, @writer_ip)
      @writer_thread = start_packet_writer
      @writer_thread.abort_on_exception = true

      running?
    end

    # @return [Boolean] true if the Receiver is listening and writing packets.
    def running?
      if type == :redirector
        @receiver.running? && writing_packets?
      else
        writing_packets?
      end
    end

    # @return [Boolean] true if ready to write packets to file.
    def writing_packets?
      !@writer_thread.nil? ? @writer_thread.alive? : false
    end

    private


    # This starts a new Thread for reading packets off of the list of packets
    # that has been read in by the listener.  If no block is given, this writes
    # all received packets (in the @packets Queue) to the +capture_file+.  If a
    # block is given, it yields each packet, parsed as an RTP::RTPPacket as well as
    # the timestamp from that packet as it was received on the socket.  If
    # +strip_headers+ is set, it only writes/yields the RTP payload to the file.
    #
    # @yield [RTP::RTPPacket] Each parsed packet that comes in over the wire.
    # @yield [Time] The timestamp from the packet as it was received on the
    #   socket.
    # @return [Thread] The packet writer thread.
    def start_packet_writer
      return @writer_thread if @writer_thread

      # If a block is given for packet inspection, perhaps we should save
      # some I/O ano not write the packet to file?
      Thread.start do
        loop do
          msg, timestamp = @packets.pop
          packet = RTP::RTPPacket.read(msg)
          packet.ssrc_id = @ssrc
          #data_to_write = @strip_headers ? packet.rtp_payload : packet
          @writer_thread.send(packet.to_binary_s, 0, @writer_ip, @writer_port)
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
      log "Setting up #{protocol} socket on #{ip_address}:#{port}"

      if protocol == :UDP
        socket = UDPSocket.open
        socket.bind(ip_address, port)
      elsif protocol == :TCP
        socket = TCPServer.new(ip_address, port)
      else
        raise RTP::Error,
          "Unknown protocol requested: #{protocol}.  Options are :TCP or :UDP"
      end

      #set_socket_time_options(socket)
      #setup_multicast_socket(socket, multicast_address) if multicast?

      @rtp_port = port
      log "#{protocol} server setup to send on port #{@rtp_port}"

      socket
    end
  end
end
