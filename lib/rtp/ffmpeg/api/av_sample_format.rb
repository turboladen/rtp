module RTP
  module FFmpeg
    AVSampleFormat = enum :none, -1,
                          :u8,
                          :s16,
                          :s32,
                          :flt,
                          :dbl,
                          :u8p,
                          :s16p,
                          :s32p,
                          :fltp,
                          :dblp,
                          :nb
  end
end