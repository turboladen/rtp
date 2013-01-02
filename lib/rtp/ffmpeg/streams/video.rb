require_relative '../../logger'
require_relative '../stream'
require_relative '../video_frame'


module RTP
  module FFmpeg
    module Streams
      class Video < RTP::FFmpeg::Stream
        include LogSwitch::Mixin

        attr_reader :raw_frame, :width, :height, :pixel_format
        attr_reader :av_codec_ctx

        def initialize(av_stream, av_format_context)
          super(av_stream, av_format_context)
          @width = @av_codec_ctx[:width]
          @height = @av_codec_ctx[:height]
          @pixel_format = @av_codec_ctx[:pix_fmt]

          log "format: #{@pixel_format}"
          log "width: #{@width}"
          log "height: #{@height}"

          @raw_frame = FFmpeg::VideoFrame.new(
            :stream => self,
            :width => @width,
            :height => @height,
            :pixel_format => @pixel_format
          )

          @frame_finished = FFI::MemoryPointer.new(:int)
        end

        def decode_frame(packet)
          len = if FFmpeg.old_api?
            avcodec_decode_video(@av_codec_ctx, @raw_frame.av_frame,
              @frame_finished, packet[:data], packet[:size])
          else
            avcodec_decode_video2(@av_codec_ctx, @raw_frame.av_frame,
              @frame_finished, packet)
          end

          if len > 0
            log "Read bytes: #{len}"
          elsif len.zero?
            warn "Couldn't decompress frame"
          else
            warn "Negative return on decompressing frame; could be an error..."
          end

          if @frame_finished.read_int >= 0
            log "Frame info:"
            log "\tpict num: #{@raw_frame.av_frame[:coded_picture_number]}"
            log "\tpts: #{@raw_frame.av_frame[:pts]}"
            log "\tdts: #{@raw_frame.av_frame[:pkt_dts]}"
            return @raw_frame
          else
            log "frame_finished: #{@frame_finished.read_int}"
          end
        end
      end
    end
  end
end