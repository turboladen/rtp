require_relative '../libc'


module RTP
  module FFmpeg
    class RawVideoFile
      attr_accessor :line_size
      attr_accessor :height

      def initialize(file_name, width, height)
        @file = RTP::LibC.fopen(file_name, 'wb')
        @width = width
        @height = height
      end

      def write(data)
        raise "Must set #height before writing" unless @height
        raise "Must set #line_size before writing" unless @line_size
        line_number = 0

        while line_number < @height
          unless data.null?
            RTP::LibC.fwrite(
              data + line_number * @line_size,
              1,
              @width,
              @file
            )
          end

          line_number += 1
        end
      end

      def close
        RTP::LibC.fclose(@file)
      end
    end
  end
end