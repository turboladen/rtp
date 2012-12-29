require_relative '../logger'
require_relative 'ffmpeg'


module RTP
  class FFmpeg::VideoFrame
    include RTP::FFmpeg
    include LogSwitch::Mixin

    attr_reader :av_frame, :width, :height, :pixel_format, :stream
    attr_accessor :pts, :number

    def initialize(p={})
      @stream = p[:stream]
      @width = p[:width]
      @height = p[:height]
      @pixel_format = p[:pixel_format]

      raise ArgumentError, "no :stream" unless @stream
      raise ArgumentError, "no :width" unless @width
      raise ArgumentError, "no :heigth" unless @height
      raise ArgumentError "no :pixel_format" unless @pixel_format

      @av_frame = avcodec_alloc_frame
      raise NoMemoryError "avcodec_alloc_frame() failed" unless @av_frame

      @av_frame = AVFrame.new @av_frame

      # Set up our finalizer which calls av_free() on the av_frame.
      ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)

      log "format: #{@pixel_format}"
      log "width: #{@width}"
      log "height: #{@height}"
      bytes = avpicture_get_size(@pixel_format, @width, @height)
      log "bytes: #{bytes}"
      @buffer = FFI::MemoryPointer.new(:uchar, bytes)
      avpicture_fill(@av_frame, @buffer, @pixel_format, @width, @height)
    end

    def self.finalize(id)
      av_free(@av_frame)
    end

    def key_frame?
      @av_frame[:key_frame] == 1
    end

=begin
    def scale(p={})
      width = p[:width] || @width
      height = p[:height] || @height
      pixel_format = p[:pixel_format] || @pixel_format
      out = FFmpeg::Frame::Video.new(:width => width, :height => height,
        :pixel_format => pixel_format,
        :stream => stream)

      scale_ctx = sws_getContext(@width, @height, @pixel_format,
        width, height, pixel_format,
        :bicubic, nil, nil, nil) or
        raise NoMemoryError, "sws_getContext() failed"

      rc = sws_scale(scale_ctx, @av_frame[:data], @av_frame[:linesize], 0,
        @height, out.av_frame[:data], out.av_frame[:linesize])
      sws_freeContext(scale_ctx)

      out.pts = @pts
      out.number = @number
      out
    end
=end
  end
end
