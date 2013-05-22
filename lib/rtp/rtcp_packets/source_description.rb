require 'bindata'


module RTP
  module RTCPPackets

    # Packet type 202, aka "SDES" packet.
    class SourceDescription < BinData::Record

      # Mapping of description item types to their names.
      ITEMS = {
        1 => [:string, value: 'CNAME'],
        2 => [:string, value: 'NAME'],
        3 => [:string, value: 'EMAIL'],
        4 => [:string, value: 'PHONE'],
        5 => [:string, value: 'LOC'],
        6 => [:string, value: 'TOOL'],
        7 => [:string, value: 'NOTE'],
        8 => [:string, value: 'PRIV']
      }

      endian :big

      # The list of sources and their descriptions.
      #
      # @return [BinData::Struct]
      struct :source_list do

        # The SSRC or CSRC of the source.
        #
        # @return [BinData::Uint32be]
        uint32 :ssrc_csrc

        # List of values as defined by the source.
        #
        # @return [BinData::Array]
        array :sdes_list, read_until: lambda { index == self.item_count } do

          # The integer value of the value type.
          #
          # @return [BinData::Uint8be]
          uint8 :type

          # This is not part of the spec, but is added in for usability.  It's
          # simply a mapping of the :type to the type's name, as defined in the
          # spec.
          #
          # @return [BinData::String]
          choice :type_name, choices: ITEMS, selection: :type

          # Length of the value.
          #
          # @return [BinData::Uint8be]
          uint8 :value_length

          # The actual value of the item.
          #
          # @return [BinData::String]
          string :sdes_value, read_length: :value_length
        end
      end
    end
  end
end
