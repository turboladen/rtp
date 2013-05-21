require 'bindata'
require_relative 'rtcp_packets/sender_report'


module RTP
  class RTCPPacket < BinData::Record
    PACKET_TYPES = {
      200 => RTP::RTCPPackets::SenderReport
    }

    endian :big

    array :packets, initial_length: 6 do
      #---------------------------------------------------------------------------
      # RTCP Header
      #---------------------------------------------------------------------------

      # @return [BinData::Bit2]
      bit2 :version

      # @return [BinData::Bit1]
      bit1 :padding

      # @return [BinData::Bit5]
      bit5 :item_count

      # @return [BinData::Bit8]
      bit8 :packet_type

      # @return [BinData::Uint32be]
      uint16 :packet_length

      # @return [BinData::Choice]
      choice :packet_data, choices: PACKET_TYPES, selection: :packet_type

      # @return [BinData::String]
      string :pad_data, read_length: lambda { self.padding.zero? ? 0 : 8 }
    end
  end
end
