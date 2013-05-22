require 'spec_helper'
require 'rtp/session'


describe RTP::Session do
  let(:ssrc) { '00000000' }
  let(:ip) { '1.2.3.4' }
  let(:rtp_port) { 11111 }
  let(:rtcp_port) { 22222 }
  let(:rtp_receiver) { double 'EM.Callback' }
  let(:rtp_sender) { double 'EM.Callback' }
  let(:rtcp_receiver) { double 'EM.Callback' }
  let(:rtcp_sender) { double 'EM.Callback' }

  subject do
    RTP::Session.new(ssrc, ip, rtp_port, rtcp_port)
  end

  its(:ssrc) { should eq ssrc }
  its(:ip) { should eq ip }
  its(:rtp_port) { should eq rtp_port }
  its(:rtcp_port) { should eq rtcp_port }

  describe '#start_rtp' do
    before do
      subject.instance_variable_set(:@rtp_receiver, rtp_receiver)
      subject.instance_variable_set(:@rtp_sender, rtp_sender)
    end

    it 'opens a UDP connection on the IP and RTP port' do
      EM.should_receive(:open_datagram_socket).
        with(ip, rtp_port, RTP::RTPConnection, ssrc, rtp_receiver, rtp_sender)

      subject.send(:start_rtp)
    end
  end

  describe '#start_rtcp' do
    context 'receiver callback is provided' do
      before do
        subject.instance_variable_set(:@rtcp_receiver, rtcp_receiver)
        subject.instance_variable_set(:@rtcp_sender, rtcp_sender)
      end

      subject do
        RTP::Session.new(ssrc, ip, rtp_port, rtcp_port)
      end

      it 'opens a UDP connection on the IP and RTCP port' do
        EM.should_receive(:open_datagram_socket).
          with(ip, rtcp_port, RTP::RTCPConnection, rtcp_receiver, rtcp_sender)

        subject.send(:start_rtcp)
      end
    end

    context 'receiver callback is not provided' do
      before do
        subject.instance_variable_set(:@rtcp_sender, rtcp_sender)
      end

      it 'opens a UDP connection on the IP and RTCP port' do
        EM.should_receive(:open_datagram_socket).
          with(ip, rtcp_port, RTP::RTCPConnection, nil, rtcp_sender)

        subject.send(:start_rtcp)
      end
    end
  end
end
