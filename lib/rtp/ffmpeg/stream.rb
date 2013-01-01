require_relative 'ffmpeg'
require_relative '../logger'
require 'pp'

class String
  def hexdump
    buf = ""
    offset = 0
    words = self.unpack("N%d" % (self.length/4.0).ceil)
    until words.empty?
      line = words.shift(4).compact
      buf += sprintf("[%04x] " + ("%08x " * line.size) + "|%s|\n",
        offset * 16, *line,
        line.pack("N%d" % line.size).tr("^\040-\176","."))
      offset += 1
    end
    buf
  end
end

module RTP
  module FFmpeg
    class Stream
      include RTP::FFmpeg
      include LogSwitch::Mixin

      attr_reader :reader, :av_stream, :av_codec_ctx

      def initialize(p={})
        @reader = p[:reader] or raise ArgumentError, "no :reader"
        @av_stream = p[:av_stream] or raise ArgumentError, "no :av_stream"
        @av_codec_ctx = AVCodecContext.new(@av_stream[:codec])

        # open the codec
        codec = FFmpeg.avcodec_find_decoder(@av_codec_ctx[:codec_id])

        if codec.null?
          raise RuntimeError, "No decoder found for #{@av_codec_ctx[:codec_id]}"
        end

        #avcodec_open(@av_codec_ctx, codec) == 0 or
        #  raise RuntimeError, "avcodec_open() failed"
        rc = avcodec_open2(@av_codec_ctx, codec, nil)
        raise "Couldn't open codec" if rc < 0

        # Set up finalizer to free up resources
        ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
      end

      def self.finalize(id)
        avcodec_close(@av_codec_ctx)
      end

      def discard=(value)
        @av_stream[:discard] = value
      end

      def discard
        @av_stream[:discard]
      end

      def type
        log "type #{@av_codec_ctx[:codec_type]}"
        @av_codec_ctx[:codec_type]
      end

      def index
        @av_stream[:index]
      end

      def decode_frame(packet)
        return false
        raise NotImplementedError, "decode_frame() not defined for #{self.class}"
      end

      def each_frame(&block)
        raise ArgumentError, "No block provided" unless block_given?

        av_packet = AVPacket.new
        av_init_packet(av_packet)
        av_packet[:data] = nil
        av_packet[:size] = 0

        while av_read_frame(@reader.av_format_ctx, av_packet) >= 0
          log "Packet from stream number #{av_packet[:stream_index]}"

          if av_packet[:stream_index] == index
            frame = decode_frame(av_packet)
            rc = frame ? yield(frame) : true
          end

          av_free_packet(av_packet)

          break if rc == false
        end

        av_free(av_packet)
      end

      end
    end
  end
end


require_relative 'streams/video'
require_relative 'streams/unsupported'
