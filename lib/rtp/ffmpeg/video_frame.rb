require_relative '../logger'
require_relative 'ffmpeg'
require_relative '../ffmpeg/api/av_picture'


module RTP
  class FFmpeg::VideoFrame
    include RTP::FFmpeg
    include LogSwitch::Mixin

    attr_reader :av_frame, :width, :height, :pixel_format
    attr_accessor :pts, :number
    attr_reader :buffer_size

    def initialize(width, height, pixel_format)
      @width = width
      @height = height
      @pixel_format = pixel_format

      raise ArgumentError, "no :width" unless @width
      raise ArgumentError, "no :heigth" unless @height
      raise ArgumentError "no :pixel_format" unless @pixel_format

      #destination_picture = init_destination_picture
      init_frame

      #bytes = avpicture_get_size(@pixel_format, @width, @height)
      #log "bytes: #{bytes}"

      #@buffer = FFI::MemoryPointer.new(:uchar, bytes)
      #avpicture_fill(@av_frame, @buffer, @pixel_format, @width, @height)
      #log "av_frame: #{@av_frame.to_hash}"

      # Set up our finalizer which calls av_free() on the av_frame.
      ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
    end

    def self.finalize(id)
      av_free(@buffer)
      av_free(@av_frame)
    end

    def key_frame?
      @av_frame[:key_frame] == 1
    end

    private

    def init_frame
      @av_frame = avcodec_alloc_frame
      raise NoMemoryError "avcodec_alloc_frame() failed" unless @av_frame
      @av_frame = AVFrame.new(@av_frame)
    end

    def init_destination_picture
      av_picture = RTP::FFmpeg::AVPicture.new

      len = RTP::FFmpeg.av_image_alloc(
        av_picture[:data],
        av_picture[:linesize],
        @width,
        @height,
        @pixel_format,
        1       # align
      )

      if len < 0
        p @width
        p @height
        p @pixel_format
        raise "Could not allocate raw video buffer"
      end

      av_picture
    end
  end
end
