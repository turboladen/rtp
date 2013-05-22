require 'spec_helper'
require 'rtp/rtcp_connection'


describe RTP::RTCPConnection do
  before do
    RTP::RTCPConnection.any_instance.stub(:self_info).and_return 'localhost'
  end

  let(:receiver) { double 'EM.Callback' }
  let(:sender) { double 'EM.Callback' }
  let(:packet) { double 'RTP::RTCPPacket' }

  subject { RTP::RTCPConnection.new(1, receiver, sender) }

  describe '#receive_data' do
    let(:data) { double 'data', size: 1 }

    it 'parses the data' do
      RTP::RTCPPacket.should_receive(:read).with data
      receiver.stub(:call)

      subject.receive_data(data)
    end

    context 'receiver callback is given' do
      before do
        RTP::RTCPPacket.stub(:read).and_return packet
      end

      subject do
        RTP::RTCPConnection.new(1, receiver, sender)
      end

      it 'calls the receiver callback with the parsed packet' do
        receiver.should_receive(:call).with packet

        subject.receive_data(data)
      end
    end

    context 'receiver is not given' do
      subject { RTP::RTCPConnection.new(1, nil, sender) }

      before do
        RTP::RTCPPacket.stub(:read).and_return packet
      end

      it 'does not call the receiver callback with the parsed packet' do
        receiver.should_not_receive(:call).with packet

        subject.receive_data(data).should == packet
      end
    end
  end
end
