require 'ffi'
require 'dl'
require_relative '../helpers'

module RTP
  module FFmpeg
    extend FFI::Library
    include RTP::Helpers

    def self.old_api
      @old_api ||= false
    end

    def self.old_api?
      !!@old_api
    end

    def self.old_api=(new_value)
      @old_api = new_value
    end

    LIBRARY_FILENAME = {
        :avutil   => ENV['FFI_FFMPEG_LIBAVUTIL'],
        :avformat => ENV['FFI_FFMPEG_LIBAVFORMAT'],
        :avcodec  => ENV['FFI_FFMPEG_LIBAVCODEC'],
        #:swscale  => ENV['FFI_FFMPEG_LIBSWSCALE']
    }

    #if linux?
    #  LIBRARY_FILENAME[:avutil]   ||= "libavutil.so.49"
    #  LIBRARY_FILENAME[:avformat] ||= "libavformat.so.52"
    #  LIBRARY_FILENAME[:avcodec]  ||= "libavcodec.so.52"
    #  LIBRARY_FILENAME[:swscale]  ||= "libswscale.so.0"
    #elsif mac?
      LIBRARY_FILENAME[:avutil]   ||= "libavutil"
      LIBRARY_FILENAME[:avformat] ||= "libavformat"
      LIBRARY_FILENAME[:avcodec]  ||= "libavcodec"
    #LIBRARY_FILENAME[:swscale]  ||= "libswscale"

    #if mac?
      # Ok, this is stupid, but macports increments the major revision
      # number from 0 to 1 to make some of their code work.  We check
      # for this case here and try libswscale.0 failing back to
      # libswscale.1.
      #
      # See this commit for details:
      #   https://svn.macports.org/changeset/43550
      #LIBRARY_FILENAME[:swscale]  ||= begin
      #  DL.dlopen("libswscale.0.dylib").close
      #  "libswscale.0"
      #rescue DL::DLError
      #  "libswscale.1"
      #end
    #end
    #elsif win?
    #  warn "Not sure what libs to load under windows yet..."
    #end

    # Not actually an enum in libavutil.h, but we make it one here to
    # make the api prettier.
    AVLogLevel   = enum :quiet,   -8,
                        :panic,    0,
                        :fatal,    8,
                        :error,   16,
                        :warning, 24,
                        :info,    32,
                        :verbose, 40,
                        :debug,   48

=begin
    SWScaleFlags = enum :fast_bilinear, 0x001,
                        :bilinear,      0x002,
                        :bicubic,       0x004,
                        :x,             0x008,
                        :point,         0x010,
                        :area,          0x020,
                        :bicublin,      0x040,
                        :gauss,         0x080,
                        :sinc,          0x100,
                        :lanczos,       0x200,
                        :spline,        0x400
=end

    ###################################################
    #                                                 #
    #  Enums                                          #
    #                                                 #
    ###################################################
    require_relative 'api/av_media_type'
    require_relative 'api/av_codec_id'

    if old_api?
      require_relative 'old_api/pixel_format'
    else
      require_relative 'api/av_pixel_format'
    end

    ###################################################
    #                                                 #
    #  Functions                                      #
    #                                                 #
    ###################################################

    #--------------------------------------------------
    # libavutil
    #--------------------------------------------------
    ffi_lib LIBRARY_FILENAME[:avutil]

    attach_function :av_log_get_level, [], AVLogLevel
    attach_function :av_log_set_level, [AVLogLevel], :void
    attach_function :av_free, [:pointer], :void
    attach_function :av_malloc, [:uint], :pointer

    #--------------------------------------------------
    # libavformat
    #--------------------------------------------------
    ffi_lib LIBRARY_FILENAME[:avformat]
    attach_function :av_register_all, [], :void

    begin
      attach_function :avformat_open_input,
                      [:pointer, :string, :pointer, :int, :pointer],
                      :int
      attach_function :av_dump_format,
                      [:pointer, :int, :string, :int],
                      :void
    rescue
      warn "Using old FFmpeg API; using av_open_input_file instead of avformat_open_input"
      old_api = true
      attach_function :av_open_input_file,
                      [:pointer, :string, :pointer, :int, :pointer],
                      :int
      attach_function :dump_format,
                      [:pointer, :int, :string, :int],
                      :void
    end

    attach_function :av_find_stream_info, [:pointer], :int
    attach_function :av_read_frame, [:pointer, :pointer], :int
    attach_function :av_seek_frame, [:pointer, :int, :long_long, :int], :int
    attach_function :av_find_default_stream_index, [ :pointer ], :int

    if old_api?
      # This function is inlined in avformat, defining it here
      # for convenience.
      #
      # Original definition:
      #     static inline void av_free_packet(AVPacket *pkt)
      #     {
      #         if (pkt && pkt->destruct) {
      #             pkt->destruct(pkt);
      #         }
      #     }
      #
      def self.av_free_packet(pkt)
        return unless pkt and pkt[:destruct]

        FFI::Function.new(:void, [:pointer], pkt[:destruct],
                          :blocking => true).call(pkt)
      end
    else
      attach_function :av_free_packet, [:pointer], :void
    end

    def av_free_packet(pkt)
      RTP::FFmpeg.av_free_packet(pkt)
    end

    #--------------------------------------------------
    # libavcodec
    #--------------------------------------------------
    ffi_lib LIBRARY_FILENAME[:avcodec]
    attach_function :avcodec_find_decoder, [:int], :pointer
    attach_function :avcodec_open, [:pointer, :pointer], :int
    attach_function :avcodec_alloc_frame, [], :pointer

    if old_api?
      attach_function :avpicture_get_size, [PixelFormat, :int, :int], :int
      attach_function :avpicture_fill,
                      [:pointer, :pointer, PixelFormat, :int, :int],
                      :int
      attach_function :avcodec_decode_video, [:pointer, :pointer, :pointer,
                                              :pointer, :int], :int,
                      { :blocking => true }

    else
      attach_function :avpicture_get_size, [AVPixelFormat, :int, :int], :int
      attach_function :avpicture_fill,
                      [:pointer, :pointer, AVPixelFormat, :int, :int],
                      :int
    end

    attach_function :avcodec_decode_video2, [:pointer, :pointer, :pointer,
                                             :pointer], :int,
                    { :blocking => true }
    attach_function :avcodec_default_get_buffer, [:pointer, :pointer], :int
    attach_function :avcodec_default_release_buffer, [:pointer, :pointer], :int

    #--------------------------------------------------
    # libswscale
    #--------------------------------------------------
=begin
    ffi_lib LIBRARY_FILENAME[:swscale]
    if old_api?
      attach_function :sws_getContext,
                      [:int, :int, PixelFormat, :int, :int, PixelFormat,
                       SWScaleFlags, :pointer, :pointer, :pointer],
                      :pointer
    else
      attach_function :sws_getContext,
                      [:int, :int, AVPixelFormat, :int, :int, AVPixelFormat,
                       SWScaleFlags, :pointer, :pointer, :pointer],
                      :pointer
    end
    attach_function :sws_freeContext,
                    [:pointer],
                    :void
    attach_function :sws_scale,
                    [:pointer, :pointer, :pointer, :int,
                     :int, :pointer, :pointer],
                    :int,
                    { :blocking => true }

    callback :av_codec_context_get_buffer, [:pointer, :pointer], :int
=end

    ###################################################
    #                                                 #
    #  Definitions                                    #
    #                                                 #
    ###################################################

    AV_NOPTS_VALUE       = 0x8000000000000000
    MAX_STREAMS          = 20
    MAX_REORDER_DELAY    = 16
    MAX_STD_TIMEBASES    = 60 * 12 + 6      # new
    AVSEEK_FLAG_BACKWARD = 1
    AVSEEK_FLAG_BYTE     = 2
    AVSEEK_FLAG_ANY      = 4
    AV_TIME_BASE         = 1000000
    AV_PARSER_PTS_NB     = 4
    MAX_NUM_DATA_POINTERS = old_api? ? 4 : 8


    ###################################################
    #                                                 #
    #  Data Structures                                #
    #                                                 #
    ###################################################
    if old_api?
      warn "Using old API av_packet"
      warn "Using old API av_stream"
      warn "Using old API av_format_context"
      warn "Using old API av_codec_context"
      warn "Using old API av_frame"

      require_relative 'old_api/av_packet'
      require_relative 'old_api/av_stream'
      require_relative 'old_api/av_codec_context'
      require_relative 'old_api/av_format_context'
      require_relative 'old_api/av_frame'
    else
      require_relative 'api/av_packet'
      require_relative 'api/av_stream'
      require_relative 'api/av_codec_context'
      require_relative 'api/av_format_context'
      require_relative 'api/av_frame'
    end
  end # module FFmpeg
end # module FFI
