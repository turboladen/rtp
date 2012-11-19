require 'spec_helper'
require 'rtp/receiver'

Thread.abort_on_exception = true
RTP::Logger.log = false

describe RTP::Receiver do
  describe "#initialize" do
    it "sets default values for accessors" do
      subject.transport_protocol.should == :UDP
      subject.instance_variable_get(:@ip_address).should == '0.0.0.0'
      subject.rtp_port.should == 6970
      subject.rtcp_port.should == 6971
      subject.capture_file.should be_a Tempfile
    end

    it "isn't running" do
      subject.should_not be_running
    end
  end

  describe "#start" do
    context "running" do
      before { subject.stub(:running?).and_return true }

      it "doesn't try starting anything else" do
        subject.should_not_receive(:start_packet_writer)
        subject.should_not_receive(:init_socket)
        subject.should_not_receive(:start_listener)
        subject.start
      end
    end

    context "not running" do
      before { subject.stub(:running?).and_return false }
      let(:packet_writer) { double "@packet_writer", :abort_on_exception= => nil }
      let(:listener) { double "@listener", :abort_on_exception= => nil }

      it "initializes the listener socket, listener thread, and packet writer" do
        subject.should_receive(:start_packet_writer).and_return packet_writer
        subject.should_receive(:init_socket).with(:UDP, 6970, '0.0.0.0')
        subject.should_receive(:start_listener).and_return packet_writer

        subject.start
      end
    end
  end

  describe "#stop" do
    it "calls #stop_listener" do
      subject.should_receive(:stop_listener)
      subject.stop
    end

    it "calls #stop_packet_writer" do
      subject.should_receive(:stop_packet_writer)
      subject.stop
    end
  end

  describe "#listening?" do
    context "@listner is nil" do
      before { subject.instance_variable_set(:@listener, nil) }
      specify { subject.should_not be_listening }
    end

    context "@listener is not nil" do
      let(:listener) { double "@listener", :alive? => true }
      before { subject.instance_variable_set(:@listener, listener) }
      specify { subject.should be_listening }
    end
  end

  describe "#writing_packets?" do
    context "@packet_writer is nil" do
      before { subject.instance_variable_set(:@packet_writer, nil) }
      specify { subject.should_not be_writing_packets }
    end

    context "@packet_writer is not nil" do
      let(:writer) { double "@packet_writer", :alive? => true }
      before { subject.instance_variable_set(:@packet_writer, writer) }
      specify { subject.should be_writing_packets }
    end
  end

  describe "#running?" do
    context "listening and writing packets" do
      before do
        subject.stub(:listening?).and_return(true)
        subject.stub(:writing_packets?).and_return(true)
      end

      specify { subject.should be_running }
    end

    context "listening, not writing packets" do
      before do
        subject.stub(:listening?).and_return(true)
        subject.stub(:writing_packets?).and_return(false)
      end

      specify { subject.should_not be_running }
    end

    context "not listening, writing packets" do
      before do
        subject.stub(:listening?).and_return(false)
        subject.stub(:writing_packets?).and_return(true)
      end

      specify { subject.should_not be_running }
    end

    context "not listening, not writing packets" do
      before do
        subject.stub(:listening?).and_return(false)
        subject.stub(:writing_packets?).and_return(false)
      end

      specify { subject.should_not be_running }
    end
  end

  describe "#rtp_port=" do
    specify {
      subject.rtp_port.should == 6970
      subject.rtcp_port.should == 6971

      subject.rtp_port = 10000

      subject.rtp_port.should == 10000
      subject.rtcp_port.should == 10001
    }
  end

  #----------------------------------------------------------------------------
  # PRIVATES
  #----------------------------------------------------------------------------

  describe "#start_packet_writer" do
    let(:packet) { double "RTP::Packet" }

    before do
      Thread.stub(:start).and_yield
      subject.stub(:loop).and_yield
      subject.instance_variable_set(:@packets, [packet])
    end

    after do
      Thread.unstub(:start)
    end

    context "@strip_headers is false" do
      before { subject.instance_variable_set(:@strip_headers, false) }

      it "adds the incoming data to @payload_data buffer" do
        packet.should_not_receive(:[])
        subject.instance_variable_get(:@capture_file).should_receive(:write).
          with packet
        subject.send(:start_packet_writer)
      end
    end

    context "@strip_headers is true" do
      before { subject.instance_variable_set(:@strip_headers, true) }

      it "adds the stripped data to @payload_data buffer" do
        packet.should_receive(:[]).with("rtp_payload").and_return("payload_data")
        subject.instance_variable_get(:@capture_file).should_receive(:write).
          with "payload_data"
        subject.send(:start_packet_writer)
      end
    end
  end

  describe "#init_socket" do
    let(:udp_server) do
      double "UDPSocket", setsockopt: nil
    end

    let(:tcp_server) do
      double "TCPServer", setsockopt: nil
    end

    context "UDP" do
      before do
        UDPSocket.should_receive(:open).and_return udp_server
      end

      it "returns a UDPSocket" do
        udp_server.should_receive(:bind).with('0.0.0.0', 1234)
        subject.send(:init_socket, :UDP, 1234, '0.0.0.0').should == udp_server
      end

      it "sets socket options to get the timestamp" do
        udp_server.stub(:bind)
        subject.should_receive(:set_socket_time_options).with(udp_server)
        subject.send(:init_socket, :UDP, 1234, '0.0.0.0')
      end
    end

    context "TCP" do
      before do
        TCPServer.should_receive(:new).with('0.0.0.0', 1234).and_return tcp_server
      end

      it "returns a TCPServer" do
        subject.send(:init_socket, :TCP, 1234, '0.0.0.0').should == tcp_server
      end
    end

    context "not UDP or TCP" do
      it "raises an RTP::Error" do
        expect {
          subject.send(:init_socket, :BOBO, 1234, '1.2.3.4')
        }.to raise_error RTP::Error
      end
    end

    context "multicast" do
      context "multicast_address given" do
        pending
      end

      context "multicast_address not given" do
        pending
      end
    end
  end

  describe "#multicast?" do
    context "is not multicast" do
      specify { subject.should_not be_multicast }
    end

    context "is multicast 224.0.0.0" do
      subject { RTP::Receiver.new(ip_address: '224.0.0.0') }
      specify { subject.should be_multicast }
    end

    context "is multicast 239.255.255.255" do
      subject { RTP::Receiver.new(ip_address: '239.255.255.255') }
      specify { subject.should be_multicast }
    end
  end

  describe "#start_listener" do
    let(:listener) do
      l = double "Thread"
      l.stub(:abort_on_exception=)

      l
    end

    let(:data) do
      d = double "data"
      d.stub(:size)

      d
    end

    let(:timestamp) { double "timestamp" }

    let(:message) do
      m = double "msg"
      m.stub(:first).and_return data
      m.stub_chain(:last, :timestamp).and_return timestamp

      m
    end

    let(:socket) do
      double "Socket", recvmsg: message
    end

    it "starts a new Thread and returns that" do
      Thread.should_receive(:start).with(socket).and_return listener
      subject.send(:start_listener, socket).should == listener
    end

    it "receives data from the client and hands it to RTP::Packet to read" do
      Thread.stub(:start).and_yield
      subject.stub(:loop).and_yield

      socket.should_receive(:recvmsg).with(1500).and_return message

      packet = double "RTP::Packet"
      RTP::Packet.should_receive(:read).with(data).and_return packet

      subject.send(:start_listener, socket)

      Thread.unstub(:start)
    end

    it "extracts the timestamp of the received data and adds it to @packet_timestamps" do
      pending
    end
  end

  describe "#stop_listener" do
    let(:listener) { double "@listener" }

    before do
      subject.instance_variable_set(:@listener, listener)
    end

    context "listening" do
      before { subject.stub(:listening?).and_return true }

      it "kills the listener and resets it" do
        listener.should_receive(:kill)
        subject.send(:stop_listener)
        subject.instance_variable_get(:@listener).should be_nil
      end
    end

    context "not listening" do
      before { subject.stub(:listening?).and_return false }

      it "listener doesn't get killed but is reset" do
        listener.should_not_receive(:kill)
        subject.send(:stop_listener)
        subject.instance_variable_get(:@listener).should be_nil
      end
    end
  end

  describe "#stop_packet_writer" do
    pending
  end
end
