module RTP
  module FFmpeg
    big_endian = [1].pack("I") == [1].pack("N")
    PixelFormat = enum :none, -1,
                       :yuv420p,
                       :yuyv422,
                       :rgb24,
                       :bgr24,
                       :yuv422p,
                       :yuv444p,
                       :yuv410p,
                       :yuv411p,
                       :gray8,
                       :monowhite,
                       :monoblack,
                       :pal8,
                       :yuvj420p,
                       :yuvj422p,
                       :yuvj444p,
                       :xvmc_mpeg2_mc,
                       :xvmc_mpeg2_idct,
                       :uyvy422,
                       :uyyvyy411,
                       :bgr8,
                       :bgr4,
                       :bgr4_byte,
                       :rgb8,
                       :rgb4,
                       :rgb4_byte,
                       :nv12,
                       :nv21,
                       big_endian ? :rgb32 : :bgr32_1,    # :argb
                       big_endian ? :rgb32_1 : :bgr32,    # :rgba
                       big_endian ? :bgr32 : :rgb32_1,    # :abgr
                       big_endian ? :bgr32_1 : :rgb32,    # :bgra
                       big_endian ? :gray16 : :gray16_1,  # :gray16be
                       big_endian ? :gray16_1 : :gray16,  # :gray16le
                       :yuv440p,
                       :yuvj440p,
                       :yuva420p,
                       :vdpau_h264,
                       :vdpau_mpeg1,
                       :vdpau_mpeg2,
                       :vdpau_wmv3,
                       :vdpau_vc1,
                       big_endian ? :rgb48 : :rgb48_1,    # :rgb48be
                       big_endian ? :rgb48_1 : :rgb48,    # :rgb48le
                       big_endian ? :rgb565 : :rgb565_1,  # :rgb565be
                       big_endian ? :rgb565_1 : :rgb565,  # :rgb565le
                       big_endian ? :rgb555 : :rgb555_1,  # :rgb555be
                       big_endian ? :rgb555_1 : :rgb555,  # :rgb555le
                       big_endian ? :bgr565 : :bgr565_1,  # :bgr565be
                       big_endian ? :bgr565_1 : :bgr565,  # :bgr565le
                       big_endian ? :bgr555 : :bgr555_1,  # :bgr555be
                       big_endian ? :bgr555_1 : :bgr555,  # :bgr555le
                       :vaapi_moco,
                       :vaapi_idct,
                       :vaapi_vld,
                       big_endian ? :yuv420p16_1 : :yuv420p16, # :yuv420p16le
                       big_endian ? :yuv420p16 : :yuv420p16_1, # :yuv420p16be
                       big_endian ? :yuv422p16_1 : :yuv422p16, # :yuv422p16le
                       big_endian ? :yuv422p16 : :yuv422p16_1, # :yuv422p16be
                       big_endian ? :yuv444p16_1 : :yuv444p16, # :yuv444p16le
                       big_endian ? :yuv444p16 : :yuv444p16_1, # :yuv444p16be
                       :vdpau_mpeg4,
                       :dxva2_vld,
                       big_endian ? :rgb444 : :rgb444_1,  # :rgb444be
                       big_endian ? :rgb444_1 : :rgb444,  # :rgb444le
                       big_endian ? :bgr444 : :bgr444_1,  # :bgr444be
                       big_endian ? :bgr444_1 : :bgr444,  # :bgr444le
                       :y400a

  end
end