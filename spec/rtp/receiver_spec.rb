require_relative '../spec_helper'
require 'rtp/receiver'

Thread.abort_on_exception = true
RTP.log = false

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

      it "initializes @packet_timeatamps" do
        subject.instance_variable_get(:@packet_timestamps).should == []
      end

      it "initializes a Queue for writing to file" do
        subject.instance_variable_get(:@write_to_file_queue).should be_a Queue
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
    context "UDP" do
      it "calls #init_udp_server with port 9000" do
        subject.should_receive(:init_udp_server).with(9000)
        subject.init_server(:UDP)
      end

      it "returns a UDPSocket" do
        subject.init_server(:UDP).should be_a UDPSocket
      end
    end

    context "TCP" do
      it "calls #init_tcp_server with port 9000" do
        subject.should_receive(:init_tcp_server).with(9000)
        subject.init_server(:TCP)
      end

      it "returns a TCPServer" do
        subject.init_server(:TCP).should be_a(TCPServer)
      end
    end

    it "raises an RTP::Error when some other protocol is given" do
      expect { subject.init_server(:BOBO) }.to raise_error RTP::Error
    end
  end

  describe "#init_udp_server" do
    let(:udp_server) do
      double "UDPSocket", setsockopt: nil
    end

    it "returns a UDPSocket" do
      subject.init_udp_server(subject.rtp_port).should be_a UDPSocket
    end

    context "when port 9000 - 9048 are taken" do
      it "retries MAX_PORT_NUMBER_RETRIES times then returns the UDPSocket" do
        udp_server.should_receive(:bind).exactly(50).times.and_raise(Errno::EADDRINUSE)
        udp_server.should_receive(:bind).with('0.0.0.0', 9050)
        UDPSocket.stub(:open).and_return(udp_server)

        subject.init_udp_server(9000).should == udp_server

        UDPSocket.unstub(:open)
      end
    end

    context "when no available ports" do
      before do
        UDPSocket.should_receive(:open).exactly(51).times.and_raise(Errno::EADDRINUSE)
      end

      it "retries 50 times to get a port then allows the Errno::EADDRINUSE to raise" do
        expect { subject.init_udp_server(9000) }.to raise_error Errno::EADDRINUSE
      end

      it "sets @rtp_port back to 9000 after trying all" do
        expect { subject.init_udp_server(9000) }.to raise_error Errno::EADDRINUSE
        subject.rtp_port.should == 9000
      end
    end
  end

  describe "#init_tcp_server" do
    it "returns a TCPSocket" do
      subject.init_tcp_server(3456).should be_a TCPSocket
    end

    it "uses port a port between 9000 and 9000 + MAX_PORT_NUMBER_RETRIES" do
      subject.init_tcp_server(9000)
      subject.rtp_port.should >= 9000
      subject.rtp_port.should <= 9000 + RTP::Receiver::MAX_PORT_NUMBER_RETRIES
    end
  end

  describe "#run" do
    it "calls #start_file_builder and #start_listener" do
      subject.should_receive(:start_listener)
      subject.should_receive(:start_file_builder)
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

    it "calls #stop_file_builder" do
      subject.should_receive(:stop_file_builder)
      subject.stop
    end

    it "sets @write_to_file_queue back to a new Queue" do
      queue = subject.instance_variable_get(:@write_to_file_queue)
      subject.stop
      subject.instance_variable_get(:@write_to_file_queue).should_not equal queue
      subject.instance_variable_get(:@write_to_file_queue).should_not be_nil
    end
  end

  describe "#start_file_builder" do
    let(:file_builder) do
      fb = double "@file_builder"
      fb.stub(:abort_on_exception=)

      fb
    end

    context "#file_building? is true" do
      it "returns @file_builder" do
        subject.instance_variable_set(:@file_builder, file_builder)
        subject.stub(:file_building?).and_return true
        subject.start_file_builder.should equal file_builder
      end
    end

    context "#file_building? is false" do
      it "starts a new Thread and assigns that to @file_builder" do
        Thread.should_receive(:start).and_return file_builder
        subject.start_file_builder
        subject.instance_variable_get(:@file_builder).should equal file_builder
      end

      it "writes 'rtp_payload' data from @write_to_file_queue until the queue is empty" do
        write_to_file_queue = double "@write_to_file_queue"
        write_to_file_queue.stub(:pop).and_return({"rtp_payload" => "first"},
                                                  {"rtp_payload" => "second"})
        write_to_file_queue.should_receive(:empty?).twice.and_return(false, true)
        subject.instance_variable_set(:@write_to_file_queue, write_to_file_queue)

        rtp_file = double "@rtp_file"
        Thread.stub(:start).and_yield(rtp_file).and_return(file_builder)
        subject.stub(:loop).and_yield
        rtp_file.should_receive(:write).once

        subject.start_file_builder

        Thread.unstub(:start)
      end
    end

  end

  describe "#stop_file_builder" do
    let(:file_builder) { double "@file_builder" }

    it "sets @file_builder to nil" do
      local_file_builder = "test"
      subject.stub(:file_building?).and_return false
      subject.instance_variable_set(:@file_builder, local_file_builder)
      subject.stop_file_builder
      subject.instance_variable_get(:@file_builder)
    end

    context "#file_building? is false" do
      it "doesn't get #kill called on it" do
        file_builder.should_not_receive(:kill)
        subject.instance_variable_set(:@file_builder, file_builder)
        subject.stub(:file_building?).and_return false
        subject.stop_file_builder
      end
    end

    context "#file_building? is true" do
      it "gets killed" do
        file_builder.should_receive(:kill)
        subject.instance_variable_set(:@file_builder, file_builder)
        subject.stub(:file_building?).and_return true
        subject.stop_file_builder
      end
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
        server.should_receive(:recvmsg).and_return message
        subject.should_receive(:init_server).and_return server
        packet = double "RTP::Packet"
        packet.stub_chain(:[], :size)
        RTP::Packet.should_receive(:read).with(data).and_return packet

        subject.start_listener

        Thread.unstub(:start)
      end

      it "extracts the timestamp of the received data and adds it to @packet_timestamps" do
        pending
      end

      it "adds the new RTP::Packet object to @write_to_file_queue" do
        pending
      end
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
