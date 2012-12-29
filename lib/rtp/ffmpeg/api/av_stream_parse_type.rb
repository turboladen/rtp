module RTP
  module FFmpeg
    AVStreamParseType = enum :none,
                             :full,
                             :headers,
                             :timestamps,
                             :full_once,
                             :full_raw, "RAW"
  end
end