require './lib/rtp/participant'
require './lib/rtp/encoder'
require 'pants/readers/av_file_demuxer'


#ip = '127.0.0.1'
ip = '239.255.0.1'

part = RTP::Participant.new
session = part.join_session(ip, 5004)

=begin
session.rtp_receiver do |packet|
  puts 'RTPPPPPPPP...'
  p packet.payload_type
  p packet.ssrc_id
end

session.rtcp_receiver do |packet|
  puts 'RTCP!!'
  p packet
end
=end


source_file = File.expand_path(__dir__ + '/../effing/spec/support/sample_mpeg4.mp4')

pants = Pants::Core.new
reader = Pants::Readers::AVFileDemuxer.new(source_file, :video, pants.callback)
encoder = reader.add_seam(RTP::Encoder, :mpeg4, 30, session.ssrc)
encoder.add_writer(session.rtp_sender)
pants.add_reader(reader)


session.start
pants.start


#part.join_session('127.0.0.1', 5004, rtcp_receiver: rtcp_receiver)
#part.join_session('239.255.0.1', 5004, rtcp_callback: rtcp_callback)

#part.join_session('127.0.0.1', 5004)

