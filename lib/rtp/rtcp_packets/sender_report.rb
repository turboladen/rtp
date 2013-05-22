require 'bindata'


module RTP
  module RTCPPackets

    # Packet type 200, aka "SR" packet.
    class SenderReport < BinData::Record
      endian :big

      # ID of the reporting sync source.
      #
      # @return [BinData:Uint32be]
      uint32 :reporter_ssrc

      # The time at which this RTCP sender report packet was sent.
      #
      # @return [BinData:Uint64be]
      struct :ntp_timestamp do
        uint32 :seconds
        uint32 :fractions_of_second
      end

      # The time at which this RTCP sender report packet was sent, but in units
      # of the RTP media clock.
      #
      # @return [BinData:Uint32be]
      uint32 :rtp_timestamp

      # The number of data packets that the sync source has generated since the
      # beginning of the session.
      #
      # @return [BinData:Uint32be]
      uint32 :senders_packet_count

      # The number of octets contained in the payload of the data packets (not
      # including headers or padding).
      #
      # @return [BinData:Uint32be]
      uint32 :senders_octet_count

    end
  end
end
