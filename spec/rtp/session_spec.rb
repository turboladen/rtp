require 'spec_helper'
require 'rtp/session'


describe RTP::Session do
  let(:ssrc) { '00000000' }
  let(:ip) { '1.2.3.4' }
  let(:rtp_port) { 11111 }
  let(:rtcp_port) { 22222 }

  subject do
    RTP::Session.new(ssrc, ip, rtp_port, rtcp_port)
  end

  its(:ssrc) { should eq ssrc }
  its(:ip) { should eq ip }
  its(:rtp_port) { should eq rtp_port }
  its(:rtcp_port) { should eq rtcp_port }

  describe '#start_rtp' do
    it 'opens a UDP connection on the IP and RTP port' do
      EM.should_receive(:open_datagram_socket).
        with(ip, rtp_port, RTP::RTPConnection, ssrc)

      subject.send(:start_rtp)
    end
  end

  describe '#start_rtcp' do
    it 'opens a UDP connection on the IP and RTCP port' do
      EM.should_receive(:open_datagram_socket).
        with(ip, rtcp_port, RTP::RTCPConnection)

      subject.send(:start_rtcp)
    end
  end
end
