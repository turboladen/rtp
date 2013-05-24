require_relative '../server'
require_relative '../logger'

Thread.abort_on_exception = true



module RTP
  module Servers
    class IOCopier
      include LogSwitch::Mixin

      def initialize(destination_ip, destination_port)
        @ip = destination_ip
        @port = destination_port
        @copier = UDPSocket.open
      end

      def write(data)
        log "WRITER: sending data to #{@ip}:#{@port} with size: #{data.size}"
        log "WRITER: 50th byte: #{data[50]}"
        @copier.send(data, 0, @ip, @port)
      end
    end


    class Redirector < RTP::Server
      include LogSwitch::Mixin

      def initialize(writer_settings, reader_settings)
        super(writer_settings)

        log "Creating #{self.class} server with settings:"
        log "\tReader settings: #{reader_settings}"
        log "\tWriter settings: #{writer_settings}"

        @reader_protocol = reader_settings[:protocol] || :UDP
        @reader_ip = reader_settings[:ip] || '0.0.0.0'
        @reader_port = reader_settings[:port]
        @reader_socket = nil
      end

      def start
        @reader_socket = init_socket(@reader_protocol, @reader_port, @reader_ip)
        @writer_socket = IOCopier.new(@writer_ip, @writer_port)

        log "Starting server..."
        @copier_thread = start_packet_copier(@reader_socket, @writer_socket)

        running?
      end

      def running?
        !@copier_thread.nil? ? @copier_thread.alive? : false
      end

      private

      def start_packet_copier(reader, writer)
        return @copier_thread if @copier_thread

        Thread.start(reader, writer) do
          loop do
            IO.copy_stream(reader, writer)
          end
        end
      end
    end
  end
end
