require 'bindata'


module RTP
  module RTCPPackets

    # Packet type 201, aka "RR" packet.
    class ReceiverReport < BinData::Record
      endian :big

      uint32 :reporter_ssrc

      uint32 :reportee_ssrc

      uint8 :loss_fraction

      uint24 :total_lost_packets

      uint32 :highest_sequence_number_received

      uint32 :interarrival_jitter

      uint32 :last_sender_report

      uint32 :delay_since_last_sender_report
    end
  end
end
