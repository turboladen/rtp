require_relative '../logger'
require_relative 'ffmpeg'
require_relative '../ffmpeg/api/av_picture'


module RTP
  class FFmpeg::VideoFrame
    include RTP::FFmpeg
    include LogSwitch::Mixin

    attr_reader :av_frame, :width, :height, :pixel_format

    def initialize(width, height, pixel_format)
      @width = width
      @height = height
      @pixel_format = pixel_format

      init_frame
      ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
    end

    def self.finalize(id)
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
  end
end
