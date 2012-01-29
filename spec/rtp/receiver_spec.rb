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

  [
    {
      start_method: "start_file_builder",
      stop_method: "stop_file_builder",
      ivar: "@file_builder"
    },
      {
        start_method: "start_listener",
        stop_method: "stop_listener",
        ivar: "@listener"
      }
  ].each do |method_set|
    describe "##{method_set[:start_method]}" do
      let!(:server) do
        s = double "A Server"
        s.stub_chain(:recvmsg, :first).and_return("not nil")
        s.stub_chain(:recvmsg, :last, :timestamp).and_return("timestamp")

        s
      end

      let!(:rtp_file) do
        r = double "rtp_file"
        r.stub(:write)

        r
      end

      before :each do
        subject.rtp_file = rtp_file
        subject.stub(:init_server).and_return(server)
        RTP::Packet.stub(:read).and_return({
          "rtp_payload" => "blah" }
        )
      end

      after(:each) do
        subject.stub(:stop_listener)
        subject.send(method_set[:stop_method].to_sym)
      end

      it "starts the #{method_set[:ivar]} thread" do
        subject.send(method_set[:start_method])
        subject.instance_variable_get(method_set[:ivar].to_sym).should be_a Thread
      end

      it "returns the same #{method_set[:ivar]} if already started" do
        subject.send(method_set[:start_method])
        original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
        new_ivar = subject.send method_set[:start_method].to_sym
        original_ivar.should equal new_ivar
      end

      if method_set[:start_method] == "start_listener"
        it "starts the server" do
          listener = double "Thread", :abort_on_exception= => nil
          Thread.stub(:start).and_yield.and_return(listener)
          subject.stub(:loop)
          subject.should_receive(:init_server)
          subject.start_listener
          Thread.unstub(:start)
        end

        it "pushes data on to the @write_to_file_queue" do
          subject.start_listener
          subject.instance_variable_get(:@write_to_file_queue).pop.should ==
            { "rtp_payload" => "blah" }
        end
      end
    end

    describe "##{method_set[:stop_method]}" do
      context "#{method_set[:ivar]} thread is running" do
        before { subject.send(method_set[:start_method]) }

        it "kills the thread" do
          original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
          original_ivar.should_receive(:kill)
          subject.send(method_set[:stop_method])
        end
      end

      context "#{method_set[:ivar]} thread isn't running" do
        it "doesn't try to kill the thread" do
          allow_message_expectations_on_nil
          original_ivar = subject.instance_variable_get(method_set[:ivar].to_sym)
          original_ivar.should_not_receive(:kill)
          subject.send(method_set[:stop_method])
        end
      end
    end
  end
end
