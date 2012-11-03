require_relative '../spec_helper'
require 'rtp/receiver'

Thread.abort_on_exception = true
RTP::Logger.log = false

describe RTP::Receiver do
  describe "#initialize" do
    context "with default parameters" do
      it "uses UDP" do
        subject.instance_variable_get(:@transport_protocol).should == :UDP
      end

      it "uses port 9000" do
        subject.instance_variable_get(:@rtp_port).should == 9000
      end

      it "creates a new Tempfile" do
        subject.instance_variable_get(:@rtp_file).should be_a Tempfile
      end

      it "initializes @packet_timestamps" do
        subject.instance_variable_get(:@packet_timestamps).should == []
      end

      it "initializes an Array for holding the data buffer" do
        subject.instance_variable_get(:@payload_data).should be_a Array
      end

      it "initializes an Array for holding the sequence_list" do
        subject.instance_variable_get(:@sequence_list).should be_a Array
      end
    end

    context "non-default parameters" do
      it "can use TCP" do
        RTP::Receiver.new(:TCP).instance_variable_get(:@transport_protocol).should == :TCP
      end

      it "can take another port" do
        RTP::Receiver.new(:UDP, 12345).instance_variable_get(:@rtp_port).should == 12345
      end

      it "can take an IO object" do
        fd = IO.sysopen("/dev/null", "w")
        io = IO.new(fd, 'w')
        capturer = RTP::Receiver.new(:UDP, 12345, io)
        capturer.instance_variable_get(:@rtp_file).should be_a IO
      end
    end

    it "isn't running" do
      subject.should_not be_running
    end
  end

  describe "#init_server" do
    let(:udp_server) do
      double "UDPSocket", setsockopt: nil
    end

    let(:tcp_server) do
      double "TCPServer", setsockopt: nil
    end

    context "UDP" do
      it "calls #init_udp_server with port 9000" do
        UDPSocket.should_receive(:open).and_return udp_server
        udp_server.should_receive(:bind).with('0.0.0.0', 9000)
        subject.init_server(:UDP)
      end

      it "returns a UDPSocket" do
        subject.init_server(:UDP).should be_a UDPSocket
      end
    end

    context "TCP" do
      it "calls #init_tcp_server with port 9000" do
        TCPServer.should_receive(:new).with(9000).and_return tcp_server
        subject.init_server(:TCP)
      end

      it "returns a TCPServer" do
        subject.init_server(:TCP).should be_a(TCPServer)
      end
    end

    it "raises an RTP::Error when some other protocol is given" do
      expect { subject.init_server(:BOBO) }.to raise_error RTP::Error
    end

    it "uses port a port between 9000 and 9000 + MAX_PORT_NUMBER_RETRIES" do
      subject.init_server(:UDP, 9000)
      subject.rtp_port.should >= 9000
      subject.rtp_port.should <= 9000 + RTP::Receiver::MAX_PORT_NUMBER_RETRIES
    end

    context "when port 9000 - 9048 are taken" do
      it "retries MAX_PORT_NUMBER_RETRIES times then returns the UDPSocket" do
        udp_server.should_receive(:bind).exactly(50).times.and_raise(Errno::EADDRINUSE)
        udp_server.should_receive(:bind).with('0.0.0.0', 9050)
        UDPSocket.stub(:open).and_return(udp_server)

        subject.init_server(:UDP, 9000).should == udp_server

        UDPSocket.unstub(:open)
      end
    end

    context "when no available ports" do
      before do
        UDPSocket.should_receive(:open).exactly(51).times.and_raise(Errno::EADDRINUSE)
      end

      it "retries 50 times to get a port then allows the Errno::EADDRINUSE to raise" do
        expect { subject.init_server(:UDP, 9000) }.to raise_error Errno::EADDRINUSE
      end

      it "sets @rtp_port back to 9000 after trying all" do
        expect { subject.init_server(:UDP, 9000) }.to raise_error Errno::EADDRINUSE
        subject.rtp_port.should == 9000
      end
    end
  end

  describe "#init_tcp_server" do
  end

  describe "#run" do
    it "calls #start_listener" do
      subject.should_receive(:start_listener)
      subject.run
    end
  end

  describe "#running?" do
    context "#listening? returns true" do
      before { subject.stub(:listening?).and_return(true) }
      it { should be_true }
    end

    context "#listening? returns true, #file_building? returns true" do
      before do
        subject.stub(:listening? => true, :file_building? => true)
        it { should be_true }
      end
    end

    context "#listening? returns true, #file_building? returns false" do
      before do
        subject.stub(:listening? => true, :file_building? => false)
        it { should be_false }
      end
    end

    context "#listening? returns false, #file_building? returns false" do
      before do
        subject.stub(:listening? => false, :file_building? => false)
        it { should be_false }
      end
    end
  end

  describe "#stop" do
    it "calls #stop_listener" do
      subject.should_receive(:stop_listener)
      subject.stop
    end

    it "calls #write_buffer_to_file" do
      subject.should_receive(:write_buffer_to_file)
      subject.stop
    end
  end

  describe "#start_listener" do
    let(:listener) do
      l = double "@listener"
      l.stub(:abort_on_exception=)

      l
    end

    context "#listening? is true" do
      before { subject.stub(:listening?).and_return true }

      it "returns @listener" do
        subject.instance_variable_set(:@listener, listener)
        subject.start_listener.should equal listener
      end
    end

    context "#listening? is false" do
      before { subject.stub(:listening?).and_return false }

      it "starts a new Thread and assigns that to @listener" do
        Thread.should_receive(:start).and_return listener
        subject.start_listener
        subject.instance_variable_get(:@listener).should equal listener
      end

      it "initializes the server socket" do
        subject.instance_variable_set(:@listener, listener)
        Thread.stub(:start).and_yield.and_return listener
        subject.should_receive(:init_server)
        subject.stub(:loop)

        subject.start_listener

        Thread.unstub(:start)
      end

      let!(:data) do
        d = double "data"
        d.stub(:size)

        d
      end

      let!(:timestamp) { double "timestamp" }

      let(:message) do
        m = double "msg"
        m.stub(:first).and_return data
        m.stub_chain(:last, :timestamp).and_return timestamp

        m
      end

      let(:server) do
        double "Server"
      end

      it "receives data from the client and hands it to RTP::Packet to read" do
        subject.instance_variable_set(:@listener, listener)
        Thread.stub(:start).and_yield.and_return listener
        server.should_receive(:recvmsg_nonblock).with(1500).and_return message
        subject.should_receive(:init_server).and_return server
        packet = double "RTP::Packet"
        packet.stub_chain(:[], :size)
        packet.stub_chain(:[], :to_i).and_return(10)
        RTP::Packet.should_receive(:read).with(data).and_return packet
        subject.stub(:write_buffer_to_file)
        subject.stub(:loop).and_yield

        subject.start_listener

        Thread.unstub(:start)
      end

      it "extracts the timestamp of the received data and adds it to @packet_timestamps" do
        pending
      end

      context "@strip_headers is false" do
        it "adds the incoming data to @payload_data buffer" do
          subject.instance_variable_set(:@listener, listener)
          Thread.stub(:start).and_yield.and_return listener
          server.should_receive(:recvmsg_nonblock).with(1500).and_return message
          subject.should_receive(:init_server).and_return server
          packet = double "RTP::Packet"
          packet.stub_chain(:[], :size)
          packet.stub_chain(:[], :to_i).and_return(0)
          RTP::Packet.stub(:read).and_return packet
          subject.stub(:write_buffer_to_file)
          subject.stub(:loop).and_yield

          subject.start_listener
          subject.instance_variable_get(:@payload_data).should == [data]
          Thread.unstub(:start)
        end
      end

      context "@strip_headers is true" do
        it "adds the stripped data to @payload_data buffer" do
          subject.instance_variable_set(:@listener, listener)
          subject.instance_variable_set(:@strip_headers, true)
          Thread.stub(:start).and_yield.and_return listener
          server.should_receive(:recvmsg_nonblock).with(1500).and_return message
          subject.should_receive(:init_server).and_return server
          packet = double "RTP::Packet"
          packet.should_receive(:[]).with("rtp_payload").twice.and_return("payload_data")
          packet.should_receive(:[]).with("sequence_number").exactly(3).times.and_return("0")
          RTP::Packet.stub(:read).and_return packet
          subject.stub(:write_buffer_to_file)
          subject.stub(:loop).and_yield

          subject.start_listener
          subject.instance_variable_get(:@payload_data).should == ["payload_data"]
          Thread.unstub(:start)
        end
      end
    end
  end

    describe "#write_buffer_to_file" do
      before do
        sequence_list = [54322, 54323, 54320, 54324, 54325, 54321]
        data = []

        sequence_list.each do |sequence|
          data[sequence] = "data#{sequence}"
        end

        subject.instance_variable_set(:@sequence_list, sequence_list)
        subject.instance_variable_set(:@payload_data, data)
      end

      it "sorts the buffer and writes to file" do
        output =  StringIO.new
        expected_output = "data54320data54321data54322data54323data54324data54325"
        subject.instance_variable_set(:@rtp_file, output)
        subject.write_buffer_to_file
        output.string.should == expected_output
      end

      it "clears the sequence list after writing to file" do
        output =  StringIO.new
        subject.instance_variable_set(:@rtp_file, output)
        subject.write_buffer_to_file
        subject.instance_variable_get(:@sequence_list).should == []
      end

      it "clears the data buffer after writing to file" do
        output =  StringIO.new
        subject.instance_variable_set(:@rtp_file, output)
        subject.write_buffer_to_file
        subject.instance_variable_get(:@payload_data).should == []
      end
    end

  describe "#stop_listener" do
    let(:listener) { double "@listener" }

    it "sets @listener to nil" do
      local_listener = "test"
      subject.stub(:listening?).and_return false
      subject.instance_variable_set(:@listener, local_listener)
      subject.stop_listener
      subject.instance_variable_get(:@listener)
    end

    context "#listeining? is false" do
      before { subject.stub(:listening?).and_return false }

      it "doesn't get #kill called on it" do
        listener.should_not_receive(:kill)
        subject.instance_variable_set(:@listener, listener)
        subject.stop_listener
      end
    end

    context "#listening? is true" do
      before { subject.stub(:listening?).and_return true }

      it "gets killed" do
        listener.should_receive(:kill)
        subject.instance_variable_set(:@listener, listener)
        subject.stop_listener
      end
    end
  end
end
