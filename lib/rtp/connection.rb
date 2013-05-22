require 'socket'
require 'ipaddr'


module RTP
  class Connection < EM::Connection

    private

    # Gets the IP and port for itself.
    #
    # @return [Array<String,Fixnum>] The IP and port.
    def self_info
      self_bytes = get_sockname[2, 6].unpack('nC4')
      port = self_bytes.first.to_i
      ip = self_bytes[1, 4].join('.')

      [ip, port]
    end

    # Sets Socket options to allow for multicasting.
    def setup_multicast_socket(ip)
      membership = IPAddr.new(ip).hton + IPAddr.new('0.0.0.0').hton
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    end

    # Checks if the IP address of the connection is a multicast address.
    #
    # @return [Boolean]
    def multicast?(ip)
      Addrinfo.ip(ip).ipv4_multicast? || Addrinfo.ip(ip).ipv6_multicast?
    end
  end
end
