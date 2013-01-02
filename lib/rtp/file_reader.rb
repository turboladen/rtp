require_relative 'ffmpeg/ffmpeg'
require_relative 'ffmpeg/stream'
require_relative 'logger'


module RTP
  class FileReader
    include LogSwitch::Mixin
    include RTP::FFmpeg

    attr_reader :streams, :av_format_context

    # @param [String] filename Path of the file to open.
    def initialize(filename)
      @filename = filename
      @streams = []

      FFmpeg.av_register_all
      FFmpeg.av_log_set_level(:debug)

      open_file(filename)
      find_stream_info

      # Set up finalizer to free up resources
      ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
      initialize_streams(p)
    end

    # Opens the A/V file using FFmpeg.
    #
    # @param [String] filename Name/path of the A/V file to read.
    # @raise [RuntimeError] If FFmpeg wasn't able to open the file.
    def open_file(filename)
      @av_format_context = FFI::MemoryPointer.new(:pointer)
      #rc = av_open_input_file(@av_format_context, @filename, nil, 0, nil)
      return_code = FFmpeg.avformat_open_input(@av_format_context, @filename, nil, 0, nil)

      unless return_code.zero?
        raise RuntimeError, "av_open_input_file() failed, filename='%s', rc=%d" %
          [filename, return_code]
      end

      @av_format_context = AVFormatContext.new(@av_format_context.get_pointer(0))
    end

    # Gets info about the streams in the file.
    #
    # @raise [RuntimeError] If FFmpeg wasn't able to find stream info.
    def find_stream_info
      return_code = av_find_stream_info(@av_format_context)

      if return_code < 0
        raise RuntimeError, "av_find_stream_info() failed, rc=#{return_code}"
      end

      log "Stream count: #{@av_format_context[:nb_streams]}"
      log "File duration: #{duration}"
      log "Position of first frame: #{@av_format_context[:start_time]}"
      log "Start time, real time: #{@av_format_context[:start_time_realtime]}"
      log "Offset of first frame: #{@av_format_context[:data_offset]}"
      log "Max chunk duration: #{@av_format_context[:max_chunk_duration]}"
      log "Max chunk size: #{@av_format_context[:max_chunk_size]}"
      log "Max index size: #{@av_format_context[:max_index_size]}"
      log "Max picture buffer: #{@av_format_context[:max_picture_buffer]}"
      log "Packet size: #{@av_format_context[:packet_size]}"
      log "Total stream bit rate: #{@av_format_context[:bit_rate]}"
    end

    # Wrapper for FFmpeg's .av_dump_format, outputting metadata about the file's
    # streams.
    def dump_format
      if FFmpeg.old_api?
        FFmpeg.dump_format(@av_format_context, 0, @filename, 0)
      else
        FFmpeg.av_dump_format(@av_format_context, 0, @filename, 0)
      end
    end

    # Video duration in (fractional) seconds.
    #
    # @return [Float] The format context's duration divided by AV_TIME_BASE.
    def duration
      @duration ||= @av_format_context[:duration].to_f / AV_TIME_BASE
    end

    def self.finalize(id)
      av_close_input_file(@av_format_context)
    end

    private

    def initialize_streams(p={})
      @av_format_context[:nb_streams].times do |i|
        av_stream = AVStream.new(@av_format_context[:streams][i].get_pointer(0))

        log "Stream #{i} info:"
        log "Codec type: #{av_stream.codec_type}"

        @streams << case av_stream.codec_type
        when :video
          log "Video stream"
          FFmpeg::Streams::Video.new(:reader => self,
            :av_stream => av_stream)
        else
          log "Unsupported stream"
          FFmpeg::Streams::Unsupported.new(:reader => self,
            :av_stream => av_stream)
        end

        # TODO: fix for 2nd stream
        break
      end
    end
  end
end