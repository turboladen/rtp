require 'bindata'


module RTP
  module RTCPPackets

    # Packet type 204, aka "APP" packet.
    class ApplicationDefined < BinData::Record
      endian :big

      # The source ID for which the packet came from.
      #
      # @return [BinData::Uint32be]
      uint32 :ssrc

      # The name of the packet type, defined by the application creator.
      #
      # @return [BinData::String]
      string :name, read_length: 32

      # The data for the packet.  Since this is defined by the application, you
      # must parse this on your own.
      #
      # @return [BinData::String]
      string :data, read_length: lambda { data_length }

      # Calculates the length of the data using the packet size minus the length
      # of the :ssrc field and :name field.
      #
      # @return [Fixnum]
      def data_length
        self.packet_length - 64
      end
    end
  end
end
