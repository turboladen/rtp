require_relative 'ffmpeg'
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

      attr_reader :reader, :av_stream, :av_codec_ctx

      def initialize(p={})
        @reader = p[:reader] or raise ArgumentError, "no :reader"
        @av_stream = p[:av_stream] or raise ArgumentError, "no :av_stream"
        @av_codec_ctx = AVCodecContext.new @av_stream[:codec]

        # open the codec
        codec = FFmpeg.avcodec_find_decoder(@av_codec_ctx[:codec_id]) or
          raise RuntimeError, "No decoder found for #{@av_codec_ctx[:codec_id]}"
        avcodec_open(@av_codec_ctx, codec) == 0 or
          raise RuntimeError, "avcodec_open() failed"
      end

      def discard=(value)
        @av_stream[:discard] = value
      end

      def discard
        @av_stream[:discard]
      end

      def type
        @av_codec_ctx[:codec_type]
      end

      def index
        @av_stream[:index]
      end

      def decode_frame(packet)
        return false
        raise NotImplementedError, "decode_frame() not defined for #{self.class}"
      end

      def each_frame
        @reader.each_frame { |frame| yield frame if frame.stream == self }
      end

      def next_frame
        frame = nil
        each_frame { |f| frame = f; break }
        frame
      end

      def skip_frames(n)
        raise RuntimeError, "Cannot skip frames when discarding all frames" if
          discard == :all
        each_frame { |f| n -= 1 != 0 }
      end

      # Seek to a specific location within the stream; the location can be either
      # a PTS value or an absolute byte position.
      #
      # Arguments:
      #   [:pts]  PTS location
      #   [:pos]  Byte location
      #   [:backward] Seek backward
      #   [:any]  Seek to non-key frames
      #
      def seek(p={})
        p = { :pts => p } unless p.is_a? Hash

        raise ArgumentError, ":pts and :pos are mutually exclusive" \
      if p[:pts] and p[:pos]

        pos = p[:pts] || p[:pos]
        flags = 0
        flags |= AVSEEK_FLAG_BYTE if p[:pos]
        flags |= AVSEEK_FLAG_BACKWARD if p[:backward]
        flags |= AVSEEK_FLAG_ANY if p[:any]

        rc = av_seek_frame(@reader.av_format_ctx, @av_stream[:index], pos, flags)
        raise RuntimeError, "av_seek_frame() failed, %d" % rc if rc < 0
        true
      end
    end
  end
end


require_relative 'streams/video'
require_relative 'streams/unsupported'
