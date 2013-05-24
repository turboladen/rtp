require 'ipaddr'
require_relative '../rtp_packet'
require_relative '../server'
require_relative '../helpers'
#require 'sys/proctable'


module RTP
  module Servers
    #module Socat
    class Socat < RTP::Server
      include LogSwitch::Mixin
      include RTP::Helpers

      RTCP_SOURCE = ["80c80006072dee6ad42c300f76c3b928377e99e5006c461ba92d8a3" +
        "081ca0006072dee6a010e49583330444e2d41414a4248513600000000"]
      MP4_RTP_MAP = "96 MP4V-ES/30000"
      MP4_FMTP = "96 profile-level-id=5;config=000001b005000001b50900000100000" +
        "0012000c888ba9860fa22c087828307"
      H264_RTP_MAP = "96 H264/90000"
      H264_FMTP = "96 packetization-mode=1;profile-level-id=428032;" +
        "sprop-parameter-sets=Z0KAMtoAgAMEwAQAAjKAAAr8gYAAAYhMAABMS0IvfjAA" +
        "ADEJgAAJiWhF78CA,aM48gA=="
      SOCAT_OPTIONS = "rcvbuf=2500000,sndbuf=2500000,sndtimeo=0.00001,rcvtimeo=0.00001"
      BLOCK_SIZE = 2000
      BSD_OPTIONS = "setsockopt-int=0xffff:0x200:0x01"

      # @return [Hash] Hash of session IDs and SOCAT commands.
      #attr_accessor :sessions
      attr_accessor :command

      # @return [Hash] Hash of session IDs and pids.
      #attr_reader :pids
      attr_reader :pid

      # @return [Hash] Hash of session IDs and RTCP threads.
      #attr_reader :rtcp_threads
      attr_reader :rtcp_thread

      # @return [Array<String>] IP address of the source camera.
      attr_accessor :source_ip

      # @return [Array<Fixnum>] Port where the source camera is streaming.
      attr_accessor :source_port

      # @return [String] IP address of the interface of the RTSP streamer.
      attr_accessor :interface_ip

      # @return [Fixnum] RTP timestamp of the source stream.
      attr_accessor :rtp_timestamp

      # @return [Fixnum] RTP sequence number of the source stream.
      attr_accessor :rtp_sequence

      # @return [String] RTCP source identifier.
      attr_accessor :rtcp_source_identifier

      # @return [Array<String>] Media type attributes.
      attr_accessor :rtp_map

      # @return [Array<String>] Media format attributes.
      attr_accessor :fmtp

      #def initialize(writer_port, reader_port, reader_ip)
      def initialize(writer_settings, reader_settings)
        super(writer_settings)

        log "Creating #{self.class} server with settings:"
        log "\tReader settings: #{reader_settings}"
        log "\tWriter settings: #{writer_settings}"

        @reader_port = reader_settings[:port]
        @reader_ip = reader_settings[:ip]
        @reader_protocol = reader_settings[:protocol]

        @processes = []
      end

      def start
        command = build_socat(@writer_ip, @writer_port, @reader_port)
        log "Running command: #{command}"
        @pid = IO.popen(command).pid

        if running?
          log "socat process running under pid: #{@pid}"
        else
          log "socat process doesn't seem to be running.  Something went wrong..."
        end

        running?
      end

      def stop
        log "Killing socat process:\n#{@pid}"
        Process.kill("HUP", @pid)
      end

      def running?
        begin
          Process.getpgid(@pid)
          true
        rescue Errno::ESRCH
          false
        end
      end

      # Generates a RTCP source ID based on the friendly name.
      # This ID is used in the RTCP communication with the client.
      # The default +RTCP_SOURCE+ will be used if one is not provided.
      #
      # @param [String] friendly_name Name to be used in the RTCP source ID.
      # @return [String] rtcp_source_id RTCP Source ID.
      #def generate_rtcp_source_id friendy_name
      #  ["80c80006072dee6ad42c300f76c3b928377e99e5006c461ba92d8a3081ca0006072dee6a010e" +
      #    friendly_name.unpack("H*").first + "00000000"].pack("H*")
      #end

      # Creates a RTP streamer using socat.
      #
      # @param [String] sid Session ID.
      # @param [String] transport_url Destination IP:port.
      # @param [Fixnum] index Stream index.
      # @return [Fixnum] The port the streamer will stream on.
      #def setup_streamer(sid, transport_url, index=1)
=begin
      def setup_streamer(transport_url, index=1)
        dest_ip, dest_port = transport_url.split ":"
        @rtcp_source_identifier ||= RTCP_SOURCE.pack("H*")

        #@rtcp_threads[sid] = Thread.start do
        @rtcp_thread = Thread.start do
          s = UDPSocket.new
          s.bind(@interface_ip, 0)

          loop do
            begin
              _, sender = s.recvfrom(36)
              s.send(@rtcp_source_identifier, 0, sender[3], sender[1])
            end
          end
        end

        @cleaner ||= Thread.start { cleanup_defunct }
        @processes ||= Sys::ProcTable.ps.map { |p| p.cmdline }
        #@sessions[sid] = build_socat(dest_ip, dest_port, local_port, index)
        @command = build_socat(dest_ip, dest_port, local_port, index)

        local_port
      end
=end

      # Start streaming for the requested session.
      #
      # @param [String] sid Session ID.
      #def start_streaming sid
      #  spawn_socat(sid, @sessions[sid])
      #end
      #def send(start_time, stop_time)
      #  spawn_socat(@command)
      #end

      # Stop streaming for the requested session.
      #
      # @param [String] sid session ID.
=begin
      def stop_streaming sid
        if sid.nil?
          disconnect_all_streams
        else
          disconnect sid
          #@rtcp_threads[sid].kill unless rtcp_threads[sid].nil?
          #@rtcp_threads.delete sid
          @rtcp_thread.kill unless rtcp_threads[sid].nil?
          @rtcp_thread = nil
        end
      end
=end

      # Returns the default stream description.
      #
      # @param[Boolean] multicast True if the description is for a multicast stream.
      # @param [Fixnum] stream_index Index of the stream type.
=begin
      def description(multicast=false, stream_index=1)
        rtp_map = @rtp_map[stream_index - 1] || H264_RTP_MAP
        fmtp = @fmtp[stream_index - 1] || H264_FMTP

        <<EOF
v=0\r
o=- 1345481255966282 1 IN IP4 #{@interface_ip}\r
s=Session streamed by "Streaming Server"\r
i=stream1\r
t=0 0\r
a=tool:LIVE555 Streaming Media v2007.07.09\r
a=type:broadcast\r
a=control:*\r
a=range:npt=0-\r
a=x-qt-text-nam:Session streamed by "Streaming Server"\r
a=x-qt-text-inf:stream1\r
m=video 0 RTP/AVP 96\r
c=IN IP4 #{multicast ? "#{multicast_ip(stream_index)}/10" : "0.0.0.0"}\r
a=rtpmap:#{rtp_map}\r
a=fmtp:#{fmtp}\r
a=control:track1\r
EOF
      end
=end

      # Disconnects the stream matching the session ID.
      #
      # @param [String] sid Session ID.
      #def disconnect sid
=begin
      def disconnect
        #pid = @pids[sid].to_i
        #@pids.delete(sid)
        #@sessions.delete(sid)
        #Process.kill(9, pid) if pid > 1000
        Process.kill(9, @pid) if @pid > 1000
      rescue Errno::ESRCH
        #log "Tried to kill dead process: #{pid}"
        log "Tried to kill dead process: #{@pid}"
      end
=end

      # Parses the headers from an RTP stream.
      #
      # @param [String] src_ip Multicast IP address of RTP stream.
      # @param [Fixnum] src_port Port of RTP stream.
      # @return [Array<Fixnum>] Sequence number and timestamp
      def parse_sequence_number(src_ip, src_port)
        sock = UDPSocket.new
        ip = IPAddr.new(src_ip).hton + IPAddr.new("0.0.0.0").hton
        sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
        sock.bind(Socket::INADDR_ANY, src_port)

        begin
          data = sock.recv_nonblock(1500)
        rescue Errno::EAGAIN
          retry
        end

        sock.close
        packet = RTP::RTPPacket.read(data)

        [packet["sequence_number"], packet["timestamp"]]
      end

      private

      # Builds a socat stream command based on the source and target
      # IP and ports of the RTP stream.
      #
      # @param [String] writer_ip IP address of the remote device you want to
      #   talk to.
      # @param [Fixnum] writer_port Port on the remote device you want to
      #   talk to.
      # @return [String] IP of the interface that would be used to talk to.
      #def build_socat(target_ip, target_port, server_port, index=1)
      def build_socat(writer_ip, writer_port, reader_port)
        paths = ["/usr/local/bin/socat", "/usr/bin/socat","/opt/local/bin/socat"]
        executable = paths.find { |path| !`which #{path}`.empty? }
        log "Found socat: #{executable}"

        if executable.empty?
          abort "socat executable not found.  Quitting."
        end

        bsd_options = mac? ? BSD_OPTIONS : ''

=begin
        "#{executable} -b #{BLOCK_SIZE} UDP-RECV:#{@reader_port},reuseaddr," +
          "#{bsd_options}" + SOCAT_OPTIONS +
          ",ip-add-membership=#{@reader_ip}:#{@writer_ip} " +
          "UDP:#{target_ip}:#{target_port},sourceport=#{server_port}," +
          SOCAT_OPTIONS
=end
        "#{executable} -b #{BLOCK_SIZE} " +
          "UDP-RECV:#{@reader_port},reuseaddr,#{bsd_options} " +
          "UDP-DATAGRAM:#{writer_ip}:#{writer_port}"
      end
    end
  end
end
