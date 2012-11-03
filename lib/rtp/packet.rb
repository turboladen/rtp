require 'bindata'

module RTP
  class Packet < BinData::Record
    endian :big

    # RTP Header
    bit2 :version
    bit1 :padding
    bit1 :extension
    bit4 :csrc_count

    bit1 :marker
    bit7 :payload_type

    uint16 :sequence_number
    uint32 :timestamp
    uint32 :ssrc_id
    array :csrc_ids, :type => :uint32, :initial_length => lambda { csrc_count }

    # Extension header is variable length if :extension == 1
    uint16 :extension_id, onlyif: :has_extension?
    uint16 :extension_length, onlyif: :has_extension?

=begin
  # h.264 payload
  # NAL section of RTP Payload
  # NAL unit header && payload header
  bit1 :nal_unit_forbidden_zero
  bit2 :nal_ref_idc
  bit5 :nal_unit_type

  # Payload byte string?
  # FU header
  bit1 :start_bit
  bit1 :end_bit
  bit1 :reserved # must be 0 and must be ignored
  bit5 :nal_unit_payload_type
=end
    count_bytes_remaining :bytes_remaining
    string :rtp_payload, read_length: lambda { bytes_remaining }

    def has_extension?
      extension == 1
    end
  end
end
