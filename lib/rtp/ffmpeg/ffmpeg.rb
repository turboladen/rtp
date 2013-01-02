require 'ffi'


module RTP
  module FFmpeg
    extend FFI::Library

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
    }

    LIBRARY_FILENAME[:avutil]   ||= "libavutil"
    LIBRARY_FILENAME[:avformat] ||= "libavformat"
    LIBRARY_FILENAME[:avcodec]  ||= "libavcodec"


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

    attach_function :av_log_set_level, [AVLogLevel], :void
    attach_function :av_malloc, [:uint], :pointer
    attach_function :av_free, [:pointer], :void
    attach_function :av_freep, [:pointer], :void

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
    attach_function :avformat_close_input, [:pointer], :void

    attach_function :av_image_alloc,
      [:pointer, :pointer, :int, :int, :int, :int], :int
    attach_function :av_image_copy,
      [:pointer, :pointer, :pointer, :pointer, :int, :int, :int], :void

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
    attach_function :avcodec_open2, [:pointer, :pointer, :pointer], :int
    attach_function :avcodec_alloc_frame, [], :pointer
    attach_function :av_init_packet, [:pointer], :void

    if old_api?
      attach_function :avcodec_decode_video, [:pointer, :pointer, :pointer,
                                              :pointer, :int], :int,
                      { :blocking => true }

    else
      attach_function :avcodec_decode_video2,
        [:pointer, :pointer, :pointer, :pointer],
        :int,
        { :blocking => true }
    end

    ###################################################
    #  Definitions                                    #
    ###################################################
    MAX_STREAMS          = 20
    MAX_REORDER_DELAY    = 16
    AV_TIME_BASE         = 1000000
    AV_NUM_DATA_POINTERS = old_api? ? 4 : 8

    ###################################################
    #  Data Structures                                #
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
