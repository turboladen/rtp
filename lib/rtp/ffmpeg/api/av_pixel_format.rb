module RTP
  module FFmpeg
    big_endian = [1].pack("I") == [1].pack("N")
    AVPixelFormat = enum :none, -1,
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
                       big_endian ? :rgb444_1 : :rgb444,  # :rgb444le
                       big_endian ? :rgb444 : :rgb444_1,  # :rgb444be
                       big_endian ? :bgr444_1 : :bgr444,  # :bgr444le
                       big_endian ? :bgr444 : :bgr444_1,  # :bgr444be
                       :gray8a,
                       big_endian ? :bgr48 : :bgr48_1,  # :bgr48be
                       big_endian ? :bgr48_1 : :bgr48,  # :bgr48le
                       :yuv420p9be,
                       :yuv420p9le,
                       :yuv420p10be,
                       :yuv420p10le,
                       :yuv422p10be,
                       :yuv422p10le,
                       :yuv444p9be,
                       :yuv444p9le,
                       :yuv444p10be,
                       :yuv444p10le,
                       :yuv422p9be,
                       :yuv422p9le,
                       :vda_vld,
                       :gbrp,
                       :gbrp9be,
                       :gbrp9le,
                       :gbrp10be,
                       :gbrp10le,
                       :gbrp16be,
                       :gbrp16le,
                       :yuva422p_libav,
                       :yuva444p_libav,
                       :yuva420p9be,
                       :yuva420p9le,
                       :yuva422p9be,
                       :yuva422p9le,
                       :yuva444p9be,
                       :yuva444p9le,
                       :yuva420p10be,
                       :yuva420p10le,
                       :yuva422p10be,
                       :yuva422p10le,
                       :yuva444p10be,
                       :yuva444p10le,
                       :yuva420p16be,
                       :yuva420p16le,
                       :yuva422p16be,
                       :yuva422p16le,
                       :yuva444p16be,
                       :yuva444p16le,
                       :rgba64be,
                       :rgba64le,
                       :bgra64be,
                       :bgra64le,
                       :zerorgb,
                       :rgb0,
                       :zerobgr,
                       :bgr0,
                       :yuva44p,
                       :yuva422p,
                       :yuv420p12be,
                       :yuv420p12le,
                       :yuv420p14be,
                       :yuv420p14le,
                       :yuv422p12be,
                       :yuv422p12le,
                       :yuv422p14be,
                       :yuv422p14le,
                       :yuv444p12be,
                       :yuv444p12le,
                       :yuv444p14be,
                       :yuv444p14le,
                       :gbrp12be,
                       :gbrp12le,
                       :gbrp14be,
                       :gbrp14le,
                       :nb
  end
end