module RTP
  module FFmpeg
    AVPictureType = enum :none,
      :i,
      :p,
      :b,
      :s,
      :si,
      :sp,
      :bi
  end
end