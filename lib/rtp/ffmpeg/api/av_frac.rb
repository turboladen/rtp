module RTP
  module FFmpeg
    class AVFrac < FFI::Struct
      layout  :val, :int64,
              :num, :int64,
              :den, :int64

      def to_f
        self[:val] + self[:num].to_f / self[:den]
      end

      def to_i
        self[:val] + self[:num] / self[:den]
      end

      def to_s
        "#<AVRational:0x%016x val=%d, num=%d, den=%d, %f>" %
            [object_id, self[:val], self[:num], self[:den], to_f]
      end
    end
  end
end
