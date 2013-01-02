require_relative '../stream'


module RTP
  module FFmpeg
    module Streams
      class Unsupported < RTP::FFmpeg::Stream
        def initialize(av_stream, av_format_context)
          super(av_stream, av_format_context)
          self.discard = :all
        end
      end
    end
  end
end