require './lib/rtp/encoder'


#Pants.logger = Logger.new('log.log')
Pants.log = true
#RTP::Logger.logger = Pants.logger
RTP::Logger.log = true

av_file = '../effer/spec/support/sample_mpeg4_iTunes.mov'
raw_video_file = 'raw_video_file'
rtp_video_file = 'rtp_video_file'


Pants.demux(av_file, 0) do |demuxer|
  #demuxer.add_writer(raw_video_file)
  encoder = demuxer.add_seam(RTP::Encoder, demuxer.codec_id, demuxer.frame_rate)

  #encoder.add_writer(rtp_video_file)
  encoder.add_writer('udp://127.0.0.1:5004')
end

=begin
pants = Pants.new
demuxer = pants.add_demuxer(av_file, :video)

# Write all demuxed packets to a file
demuxer.add_writer(raw_video_file)

# RTP encode all demuxed packets
encoder = demuxer.add_writer(:rtp_encoder)

# Add writers of the RTP-encoded packets
encoder.tee.add_writer(rtp_video_file)
#encoder.tee.add_writer('udp://127.0.0.1:5004')

pants.run
=end


if defined? av_file
  orig_file_size = File.stat(av_file).size
  puts "Original file size: #{orig_file_size}"

  if File.exists?(rtp_video_file)
    rtp_video_file_size = File.stat(rtp_video_file).size if File.exists?(rtp_video_file)
    puts "RTP video file size: #{rtp_video_file_size}" if File.exists?(rtp_video_file)
    puts "RTP difference: #{orig_file_size - rtp_video_file_size}"
    #FileUtils.rm(rtp_video_file)
  end

  if File.exists?(raw_video_file)
    raw_video_file_size = File.stat(raw_video_file).size
    puts "Raw video file size: #{raw_video_file_size}" if File.exists?(raw_video_file)
    puts "Raw difference: #{orig_file_size - raw_video_file_size}"
    FileUtils.rm(raw_video_file)
  end
end