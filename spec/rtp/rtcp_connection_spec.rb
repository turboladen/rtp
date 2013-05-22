require 'spec_helper'
require 'rtp/rtcp_connection'


describe RTP::RTCPConnection do
  before do
    RTP::RTCPConnection.any_instance.stub(:self_info).and_return 'localhost'
  end

  subject { RTP::RTCPConnection.new(1) }

  describe '#receive_data' do
    let(:data) { double 'data', size: 1 }
    let(:callback) { double 'EM.Callback' }

    it 'parses the data' do
      RTP::RTCPPacket.should_receive(:read).with data

      subject.receive_data(data)
    end

    context 'callback is given' do
      let(:packet) { double 'RTP::RTCPPacket' }

      before do
        RTP::RTCPPacket.stub(:read).and_return packet
      end

      subject do
        RTP::RTCPConnection.new(1, callback)
      end

      it 'calls the callback with the parsed packet' do
        callback.should_receive(:call).with packet

        subject.receive_data(data)
      end
    end

    context 'callback is not given' do
      let(:callback) { double 'EM.Callback' }
      let(:packet) { double 'RTP::RTCPPacket' }

      before do
        RTP::RTCPPacket.stub(:read).and_return packet
      end

      it 'does not call the callback with the parsed packet' do
        callback.should_not_receive(:call).with packet

        subject.receive_data(data).should == packet
      end
    end
  end
end
