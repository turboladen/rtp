module RTP
  module FFmpeg
    AVDiscard = enum :none, -16,
                     :default, 0,
                     :nonref, 8,
                     :bidir, 16,
                     :nonkey, 32,
                     :all, 48
  end
end