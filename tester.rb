require './lib/rtp/file_reader'
require './lib/rtp/libc'
require './lib/rtp/ffmpeg/raw_video_file'


RTP::Logger.log = true
reader = RTP::FileReader.new(ARGV.first)
reader.dump_format

video_stream = reader.streams.find { |stream| stream.type == :video }
abort "No video stream found" unless video_stream
pp video_stream

=begin
video_dst_file = RTP::FFmpeg::RawVideoFile.new('raw_video',
  video_stream.av_codec_ctx[:width],
  video_stream.av_codec_ctx[:height])

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

  video_dst_file.line_size = frame.av_frame[:linesize][0]
  video_dst_file.write(frame.av_frame[:data][0])
end

video_dst_file.close

pix_fmt = video_stream.av_codec_ctx[:pix_fmt]
width = video_stream.av_codec_ctx[:width]
height = video_stream.av_codec_ctx[:height]
cmd = "ffplay -f rawvideo "
cmd << "-pixel_format #{pix_fmt} "
cmd << "-video_size #{width}x#{height} "
cmd << "-t #{reader.av_format_context[:duration]} "
cmd << "-loglevel debug "
cmd << "raw_video"
puts "Play the output video file with the command:\n#{cmd}"
`#{cmd}`

=end

video_dst_file = RTP::LibC.fopen('raw_mpeg4_video', 'wb')

video_stream.each_packet do |packet|
  unless packet[:data].null?
    RTP::LibC.fwrite(
      packet[:data],
      packet[:size],
      1,
      video_dst_file
    )
  end
end

RTP::LibC.fclose(video_dst_file)

cmd = "ffplay -f m4v "
cmd << "-t #{reader.av_format_context[:duration]} "
cmd << "-loglevel debug "
cmd << "raw_h264_video"
puts "Play the output video file with the command:\n#{cmd}"
`#{cmd}`

