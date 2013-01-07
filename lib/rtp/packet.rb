require 'bindata'

module RTP

  # Decodes a single RTP packet into a Hash, so the packet can inspected and
  # used accordingly.  Form more info on types, see
  # {bindata}[http://bindata.rubyforge.org].
  class Packet < BinData::Record
    endian :big

    #---------------------------------------------------------------------------
    # RTP Header
    #---------------------------------------------------------------------------

    # @return [BinData::Bit2]
    bit2 :version

    # @return [BinData::Bit1]
    bit1 :padding

    # @return [BinData::Bit1]
    bit1 :extension

    # @return [BinData::Bit4]
    bit4 :csrc_count

    # @return [BinData::Bit1]
    bit1 :marker

    # @return [BinData::Bit7]
    bit7 :payload_type

    # @return [BinData::Uint16be]
    uint16 :sequence_number

    # @return [BinData::Uint32be]
    uint32 :timestamp

    # @return [BinData::Uint32be]
    uint32 :ssrc_id

    # @return [BinData::Array]
    array :csrc_ids, :type => :uint32, :initial_length => lambda { csrc_count }

    #---------------------------------------------------------------------------
    # Extension header is variable length if :extension == 1
    #---------------------------------------------------------------------------

    # @return [BinData::Uint16be]
    uint16 :extension_id, onlyif: :has_extension?

    # @return [BinData::Uint16be]
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

    # @return [BinData::String]
    string :payload, read_length: lambda { bytes_remaining }

    def has_extension?
      extension == 1
    end
  end
end
