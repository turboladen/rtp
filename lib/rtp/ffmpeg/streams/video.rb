require_relative '../../logger'
require_relative '../stream'
require_relative '../video_frame'


module RTP
  module FFmpeg
    module Streams
      class Video < RTP::FFmpeg::Stream
        include LogSwitch::Mixin

        attr_reader :raw_frame, :width, :height, :pixel_format, :buffer_size, :reader

        def initialize(p={})
          super(p)
          #@width  = p[:width]  || @av_codec_ctx[:width]
          #@height = p[:height] || @av_codec_ctx[:height]
          #@pixel_format = p[:pixel_format] || @av_codec_ctx[:pix_fmt]
          #@buffer_size = p[:buffer_size] || 1

          @raw_frame = FFmpeg::VideoFrame.new :stream => self,
            :width => @av_codec_ctx[:width],
            :height => @av_codec_ctx[:height],
            :pixel_format =>
              @av_codec_ctx[:pix_fmt]

          @frame_finished = FFI::MemoryPointer.new :int

          #@scaling_initialized = false
          #@swscale_ctx = nil
          #@buffered_frames = nil
          @last_pts = nil

          # Callback function for storing the dts at the time of buffer
          # allocation to later be used as pts.
          @av_codec_ctx[:get_buffer] = @get_buffer_callback = \
        FFI::Function.new(:void, [:pointer, :pointer]) do |ctx, frame|

            # alloc space for our pts value
            # I really want to use FFI::MemoryPointer to alloc here, but
            # due to a ffi bug (https://github.com/ffi/ffi/issues/174), I
            # cannot recover the memory in the release buffer callback.
            # For the time being we'll use av_malloc()/ac_free().
            ptr = FFI::Pointer.new av_malloc(8)
            raise MemoryError, "av_malloc() failed" if ptr.null?
            ptr.write_uint64 @last_pts

            # Grab our buffer
            ret = avcodec_default_get_buffer(ctx, frame)

            # shove the pts into it
            AVFrame.new(frame)[:opaque] = ptr

            ret
          end

          @av_codec_ctx[:release_buffer] = @release_buffer_callback = \
        FFI::Function.new(:void, [:pointer, :pointer]) do |ctx, frame|
            av_free(AVFrame.new(frame)[:opaque])
            avcodec_default_release_buffer(ctx, frame)
          end
        end

        def fps
          @av_stream[:r_frame_rate]
        end

        #def width=(width)
          #@scaling_initialized = false
        #  @width = width
        #end

        #def height=(height)
        #  @scaling_initialized = false
        #  @height = height
        #end

        #def pixel_format=(pixel_format)
        #  @scaling_initialized = false
        #  @pixel_format = pixel_format
        #end

        #def buffer_size=(frames)
        #  @scaling_initialized = false
        #  @buffer_size = frames
        #end

        def decode_frame(packet)
          #initialize_scaling unless @scaling_initialized

          # pp :read => packet[:dts]
          @last_pts = packet[:dts]
          rc = if FFmpeg.old_api?
            avcodec_decode_video(@av_codec_ctx, @raw_frame.av_frame,
              @frame_finished, packet[:data], packet[:size])
          else
            log "frame finished: #{@frame_finished}"
            avcodec_decode_video2(@av_codec_ctx, @raw_frame.av_frame,
              @frame_finished, packet)
          end
          raise RuntimeError, "avcodec_decode_video() failed, rc=#{rc}" if rc < 0

          if @frame_finished.read_int == 0
            log "Done decoding frame and returning."
            return @raw_frame
          end

          log "Not yet done decoding frame..."
          # pp :finished => @raw_frame.av_frame[:opaque].address,
          #    :pts => @raw_frame.av_frame[:pts],
          #    :dts => packet[:dts],
          #    :type => @raw_frame.av_frame[:pict_type],
          #    :key_frame => @raw_frame.av_frame[:key_frame]

          # avcodec_decode_video() returns frames in the correct pts order, and
          # according to the dranger tutorial, the packet's dts is the frame's
          # pts.  When the dts has not been set (AV_NOPTS_VALUE) use the dts from
          # the first packet of the frame which is stored in the :opaque field of
          # the AVFrame.
          @raw_frame.pts = nil
          @raw_frame.pts = packet[:dts] unless packet[:dts] == AV_NOPTS_VALUE
          @raw_frame.pts ||=
            FFI::Pointer.new(@raw_frame.av_frame[:opaque]).read_uint64

          @raw_frame.number = @av_codec_ctx[:frame_number].to_i

          #unless @swscale_ctx
          #  puts "No swscale_ctx; returning..."
            return @raw_frame
          #else
          #  puts "swscale_ctx is set; continuing..."
          #end

          # XXX Need to provide a better mechanism for making sure buffer is ready
          # for use.
          #scaled_frame = @buffered_frames.shift
          #@buffered_frames << scaled_frame

          #out_frame = scaled_frame.av_frame
          #in_frame = @raw_frame.av_frame

          # Make sure we copy the key_frame value across.
          # XXX Need to also do this for some other fields
          #out_frame[:key_frame] = in_frame[:key_frame]

          #rc = sws_scale(@swscale_ctx, in_frame[:data], in_frame[:linesize], 0,
          #  @raw_frame.height, out_frame[:data], out_frame[:linesize])
          #scaled_frame.pts = @raw_frame.pts
          #scaled_frame.number = @av_codec_ctx[:frame_number]
          #scaled_frame
        end

=begin
        private

        def initialize_scaling
          puts "initializing scaling..."
          @scaling_initialized = true
          @swscale_ctx = nil
          @buffered_frames = nil

          return if @width == @av_codec_ctx[:width] &&
            @height == @av_codec_ctx[:height] &&
            @pixel_format == @av_codec_ctx[:pix_fmt] &&
            @buffer_size < 2

          @buffered_frames = @buffer_size.times.map do
            FFmpeg::VideoFrame.new :stream => self,
              :width => @width,
              :height => @height,
              :pixel_format => @pixel_format
          end

          @swscale_ctx = sws_getContext(@av_codec_ctx[:width],
            @av_codec_ctx[:height],
            @av_codec_ctx[:pix_fmt],
            @width, @height, @pixel_format,
            :bicubic, nil, nil, nil) or
            raise NoMemoryError, "sws_getContext() failed"
        end
=end
      end
    end
  end
end