module RTP
  module FFmpeg
    class AVRational < FFI::Struct
      layout  :num, :int,
              :den, :int

      def to_f
        self[:num].to_f / self[:den]
      end

      def to_float
        to_f
      end

      def to_i
        self[:num] / self[:den]
      end

      def to_s
        "#<AVRational:0x%016x num=%d, den=%d, %f>" %
            [object_id, self[:num], self[:den], to_f]
      end
    end
  end
end