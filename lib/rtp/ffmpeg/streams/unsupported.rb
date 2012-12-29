require_relative '../stream'


module RTP
  module FFmpeg
    module Streams
      class Unsupported < RTP::FFmpeg::Stream
        def initialize(p={})
          super(p)
          self.discard = :all
        end
      end
    end
  end
end