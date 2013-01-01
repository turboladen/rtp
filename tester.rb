require './lib/rtp/file_reader'
#require 'ffi-ffmpeg'


# Allocate a reader for our video file
#reader = FFmpeg::Reader.new(ARGV[0], :pixel_format => :rgb24)
#reader = FFmpeg::Reader.new(ARGV[0])

# Dump the format information for the file
#reader.dump_format

#p reader.streams.size
#puts "Stream width: #{reader.streams.first.width}"
# Grab the first video stream in the file
#stream = reader.streams.select { |s| s.type == :video }.first

# Discard non-key frames
#stream.discard = :nonkey

# Loop through the key frames for the first video stream
#stream.each_frame do |frame|
  # Do something interesting with the frame...
  # pixel data is in frame.av_frame[:data]
#  puts "Frame size:"
#  p frame.av_frame[:pkt_size]
#end

# Open video file
=begin
RTP::putsger.puts = true
reader = RTP::FileReader.new(ARGV.first)
reader.dump_format

video_stream = reader.streams.find { |stream| stream.type == :video }
video_stream.each_frame do |frame|
  puts "frame pict type: #{frame.av_frame[:pict_type]}"
  puts "frame format: #{frame.av_frame[:format]}"
  puts "frame width: #{frame.av_frame[:width]}"
  puts "frame height: #{frame.av_frame[:height]}"
  puts "frame number of audio samples: #{frame.av_frame[:nb_samples]}"
  puts "frame presentation time stamp: #{frame.av_frame[:pts]}"
  puts "frame coded picture number: #{frame.av_frame[:coded_picture_number]}"
  puts "frame display picture number: #{frame.av_frame[:display_picture_number]}"
  puts "frame quality: #{frame.av_frame[:quality]}"
  puts "frame packet size: #{frame.av_frame[:pkt_size]}"
end
=end


=begin

require './lib/rtp/ffmpeg/ffmpeg'

RTP::FFmpeg.av_register_all
RTP::FFmpeg.av_log_set_level(48)

# Open file
av_format_ctx = FFI::MemoryPointer.new(:pointer)
return_code = RTP::FFmpeg.avformat_open_input(av_format_ctx, ARGV[0], nil, 0, nil)

unless return_code.zero?
  raise RuntimeError, "av_open_input_file() failed, filename='%s', rc=%d" %
    [filename, return_code]
end

# Get stream info
av_format_ctx = RTP::FFmpeg::AVFormatContext.new(av_format_ctx.get_pointer(0))
return_code = RTP::FFmpeg::av_find_stream_info(av_format_ctx)
raise RuntimeError, "av_find_stream_info() failed, rc=#{return_code}" if return_code < 0

puts "Streams: #{av_format_ctx[:nb_streams]}"
puts "video codec id: #{av_format_ctx[:video_codec_id]}"
puts "video start time: #{av_format_ctx[:start_time]}"
puts "video packet size: #{av_format_ctx[:packet_size]}"
=end

RTP::Logger.log = true
reader = RTP::FileReader.new(ARGV.first)
reader.dump_format

=begin
# print file metadata
RTP::FFmpeg.av_dump_format(av_format_ctx, 0, ARGV[0], 0)


# Get the video stream
av_stream = nil
av_format_ctx[:nb_streams].times do |i|
  av_stream = RTP::FFmpeg::AVStream.new(av_format_ctx[:streams][i].get_pointer(0))

  puts "Stream index: #{av_stream[:index]}"
  puts "Stream id: #{av_stream[:id]}"
  puts "Stream codec: #{av_stream.codec}"
  puts "Stream codec type: #{av_stream.codec_type}"
  puts "Stream codec bit rate: #{av_stream.bit_rate}"
  break   # just get the first stream
end



# Get the codec context for the video stream
av_codec_ctx = RTP::FFmpeg::AVCodecContext.new(av_stream[:codec])
codec = RTP::FFmpeg.avcodec_find_decoder(av_codec_ctx[:codec_id])

raise "Unsupported codec" if codec.null?

rc = RTP::FFmpeg.avcodec_open2(av_codec_ctx, codec, nil)
raise "Couldn't open codec" if rc < 0
av_picture = RTP::FFmpeg::AVPicture.new

len = RTP::FFmpeg.av_image_alloc(
  av_picture[:data],
  av_picture[:linesize],
  av_codec_ctx[:width],
  av_codec_ctx[:height],
  av_codec_ctx[:pix_fmt],
  1       # align
)
if len < 0
  p av_codec_ctx[:width]
  p av_codec_ctx[:height]
  p av_codec_ctx[:pix_fmt]
  raise "Could not allocate raw video buffer"
end

video_dst_bufsize = len


frame = RTP::FFmpeg.avcodec_alloc_frame
raise "Couldn't allocate frames" if frame.null?
frame = RTP::FFmpeg::AVFrame.new(frame)

# Reading the data
frame_finished = FFI::MemoryPointer.new :int
=end

video_stream = reader.streams.find { |stream| stream.type == :video }
abort "No video stream found" unless video_stream
pp video_stream

=begin
packet = RTP::FFmpeg::AVPacket.new

#??
RTP::FFmpeg.av_init_packet(packet)
packet[:data] = nil
packet[:size] = 0

raw_video_file = File.new('raw_video', 'wb')
i = 0
frame_number = 0

while(RTP::FFmpeg.av_read_frame(av_format_ctx, packet) >= 0)
  if packet[:stream_index] == 0
    break if packet[:size].zero?

    len = RTP::FFmpeg.avcodec_decode_video2(av_codec_ctx, frame, frame_finished, packet)

    if len > 0
      puts "Read bytes: #{len}"
    elsif len.zero?
      warn "Couldn't decompress frame"
    else
      warn "Negative return on decompressing frame; could be an error..."
    end

    #if frame_finished.read_int == 0
    puts "frame finished: #{frame_finished.read_int}"
    if frame_finished.read_int != 0
      puts "Frame #{frame_number}: pict num: #{frame[:coded_picture_number]} pts: #{frame[:pts]}"

      RTP::FFmpeg.av_image_copy(
        av_picture[:data],
        av_picture[:linesize],
        frame[:data],
        frame[:linesize],
        av_codec_ctx[:pix_fmt],
        av_codec_ctx[:width],
        av_codec_ctx[:height]
      )

      #puts "data", av_picture[:data].to_ptr.read_pointer.read_string_to_null
      #puts "dest data", av_picture[:data].to_ptr.read_string
      #puts "src data", frame[:data].to_ptr.read_string
      #raw_video_file.write(av_picture[:data].to_ptr.read_pointer.read_string_to_null)
      #raw_video_file.write(av_picture[:data].to_ptr.read_string)
      raw_video_file.write(frame[:data].to_ptr.read_string)

      frame_number += 1
    end

    raw_video_file.write(packet[:data].read_string)

    #RTP::FFmpeg.av_free_packet(packet)

    puts "i: #{i}"
    i += 1
  elsave
    #puts "packet for stream #{packet[:stream_index]}"
    #puts "packet duration #{packet[:duration]}"
  end
end
=end

video_dst_file = RTP::FFmpeg.fopen('raw_video', "wb")

video_stream.each_frame do |frame|
  puts "frame pict type: #{frame.av_frame[:pict_type]}"
  puts "frame format: #{frame.av_frame[:format]}"
  puts "frame width: #{frame.av_frame[:width]}"
  puts "frame height: #{frame.av_frame[:height]}"
  puts "frame number of audio samples: #{frame.av_frame[:nb_samples]}"
  puts "frame presentation time stamp: #{frame.av_frame[:pts]}"
  puts "frame coded picture number: #{frame.av_frame[:coded_picture_number]}"
  puts "frame display picture number: #{frame.av_frame[:display_picture_number]}"
  puts "frame quality: #{frame.av_frame[:quality]}"
  puts "frame packet size: #{frame.av_frame[:pkt_size]}"

  video_dst_bufsize = frame.buffer_size
  puts "buffer size: #{video_dst_bufsize}"

  RTP::FFmpeg.fwrite(
    frame.av_frame[:data][0],
    1,
    video_dst_bufsize,
    video_dst_file
  )
=begin
  #memBuf = FFI::MemoryPointer.new(:char, frame.buffer_size)
  #memBuf = FFI::MemoryPointer.new(:char, frame.av_frame[:data].size)
  memBuf = FFI::MemoryPointer.new(:char, frame[:data].size)
  #memBuf.put_bytes(0, frame.av_frame[:data].to_ptr.read_string_to_null)
  memBuf.put_bytes(0, frame[:data].to_ptr.read_string_to_null)
  puts "membuf size: #{memBuf.size}"
  RTP::FFmpeg.fwrite(
    memBuf,
    1,
    #frame.buffer_size,
    buffer_size,
    video_dst_file
  )
=end

=begin
  av_picture = RTP::FFmpeg::AVPicture.new

  RTP::FFmpeg.av_image_copy(
    av_picture[:data], av_picture[:linesize],
    frame.av_frame[:data], frame.av_frame[:linesize],
    video_dec_ctx[:pix_fmt], video_dec_ctx[:width], video_dec_ctx[:height]
  )

  memBuf = FFI::MemoryPointer.new(:char, av_picture[:data].size)
  memBuf.put_bytes(0, av_picture[:data].to_ptr.read_string_to_null)
  RTP::FFmpeg.fwrite(
    memBuf,
    1,
    frame.buffer_size,
    video_dst_file
  )
=end
end


pix_fmt = video_stream.av_codec_ctx[:pix_fmt]
width = video_stream.av_codec_ctx[:width]
height = video_stream.av_codec_ctx[:height]
cmd = "ffplay -f rawvideo "
cmd << "-pixel_format #{pix_fmt} "
cmd << "-video_size #{width}x#{height} "
cmd << "-t #{reader.av_format_ctx[:duration]} "
cmd << "-b #{reader.av_format_ctx[:bit_rate]} "
cmd << "-loglevel debug "
cmd << "raw_video"
puts "Play the output video file with the command:\n#{cmd}"
`#{cmd}`

RTP::FFmpeg.fclose(video_dst_file)

=begin
# Clean up
RTP::FFmpeg.av_free_packet(packet)
RTP::FFmpeg.av_free(frame)
#RTP::FFmpeg.avcodec_close(av_codec_ctx)
#RTP::FFmpeg.avformat_close_input(av_format_ctx)

=end

