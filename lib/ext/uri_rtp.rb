require 'uri'

module URI
  class RTP < HTTP
    DEFAULT_PORT = 5004
  end

  @@schemes['RTP'] = RTP

  class RTCP < HTTP
    DEFAULT_PORT = 5005
  end

  @@schemes['RTCP'] = RTCP
end
