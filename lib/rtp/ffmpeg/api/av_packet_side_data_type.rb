module RTP
  module FFmpeg
    AVPacketSideDataType = enum :palette,
      :new_extradata,
      :param_change,
      :h263_mb_info,
      :skip_samples, 70,
      :jp_dualmono,
      :strings_metadata,
      :subtitle_position
  end
end