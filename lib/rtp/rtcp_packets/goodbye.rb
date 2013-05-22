require 'bindata'


module RTP
  module RTCPPackets

    # Packet type 203, aka "BYE" packet.
    class Goodbye < BinData::Record
      endian :big

      # The list of SSRCs that are leaving.
      #
      # @return [BinData::Array]
      array :ssrc_list, read_until: lambda { index == self.item_count } do

        # The SSRC of the source that's leaving.
        #
        # @return [BinData::Uint32be]
        uint32 :ssrc
      end

      # Length of the reason for leaving string, if given.
      #
      # @return [BinData::Uint8be]
      uint8 :reason_length

      # The reason the SSRCs have left.
      #
      # @return [BinData::String]
      string :reason_for_leaving, read_length: :reason_length
    end
  end
end
