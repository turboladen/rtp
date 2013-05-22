require 'bindata'
Dir[File.dirname(__FILE__) + '/rtcp_packets/*.rb'].each(&method(:require))


module RTP
  class RTCPPacket < BinData::Record
    FIRST_PACKET_TYPES = {
      200 => RTP::RTCPPackets::SenderReport,
      201 => RTP::RTCPPackets::ReceiverReport
    }

    COMPOUND_PACKET_TYPES = {
      202 => RTP::RTCPPackets::SourceDescription,
      203 => RTP::RTCPPackets::Goodbye,
      204 => RTP::RTCPPackets::ApplicationDefined
    }

    endian :big

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
    choice :packet_data, choices: FIRST_PACKET_TYPES, selection: :packet_type

    # @return [BinData::String]
    string :pad_data, read_length: lambda { self.padding.zero? ? 0 : 8 }

    # @return [BinData::Array]
    array :packets, read_until: lambda { self.item_count } do
      #---------------------------------------------------------------------------
      # Header
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
      choice :packet_data, choices: COMPOUND_PACKET_TYPES, selection: :packet_type

      # @return [BinData::String]
      string :pad_data, read_length: lambda { self.padding.zero? ? 0 : 8 }
    end
  end
end
