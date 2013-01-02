require_relative '../libc'
require_relative 'api/av_picture'


module RTP
  module FFmpeg

    # Handles writing raw video frames to a file.
    class RawVideoFile

      # @param [String] file_name The name/path of the file to write to.
      # @param [Fixnum] width Width of the frames to write.
      # @param [Fixnum] height Height of the frames to write.
      # @param [Fixnum] pixel_format Pixel format of the frames to write.
      def initialize(file_name, width, height, pixel_format)
        @file = RTP::LibC.fopen(file_name, 'wb')
        @width = width
        @height = height
        @pixel_format = pixel_format
      end

      # Properly aligns frames before writing to file, then writes the frame out
      # to the file.
      #
      # @param [FFI::Struct::InlineArray] data +data+ infor from an
      #   RTP::FFmpeg::AVFrame.
      # @param [Fixnum] line_size +linesize+ info from an RTP::FFmpeg::AVFrame.
      def write(data, line_size)
        dest_picture, destination_buffer_size = init_destination_picture

        RTP::FFmpeg.av_image_copy(
          dest_picture[:data], dest_picture[:linesize],
          data, line_size,
          @pixel_format, @width, @height
        )

        RTP::LibC.fwrite(
          dest_picture[:data][0],
          1,
          destination_buffer_size,
          @file
        )

        RTP::FFmpeg.av_freep(dest_picture)
      end

      # Closes the file.
      #
      # @return [Fixnum] 0 if it was successfully closed.
      def close
        RTP::LibC.fclose(@file)
      end

      private

      # Creates the destination AVPicture structure that will be used to copy
      # the originating frame from.  This is necessary for writing raw data
      # since a raw data file must have pictures all aligned.
      #
      # @return [Array<RTP::FFmpeg::AVPicture,Fixnum>]
      def init_destination_picture
        dest_picture = RTP::FFmpeg.avcodec_alloc_frame
        raise NoMemoryError unless dest_picture
        dest_picture = RTP::FFmpeg::AVPicture.new(dest_picture)

        destination_buffer_size = RTP::FFmpeg.av_image_alloc(
          dest_picture[:data],
          dest_picture[:linesize],
          @width,
          @height,
          @pixel_format,
          1 # align
        )

        if destination_buffer_size < 0
          p @width
          p @height
          p @pixel_format
          raise "Could not allocate raw video buffer"
        end

        return dest_picture, destination_buffer_size
      end
    end
  end
end