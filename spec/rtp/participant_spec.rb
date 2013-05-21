require 'spec_helper'
require 'rtp/participant'


describe RTP::Participant do
  its(:sessions) { should be_empty }

  describe '#join_session' do
    let(:ip) { '1.2.3.4' }
    let(:rtp_port) { 5678 }
    let(:rtcp_port) { 5679 }
    let(:session) { double 'RTP::Session' }

    before do
      session.should_receive :start
      EM.stub(:run).and_yield
    end

    after do
      EM.unstub(:run)
    end

    it 'adds the joined session to the list of sessions it is part of' do
      RTP::Session.stub(:new).and_return session

      expect {
        subject.join_session(ip, rtp_port)
      }.to change { subject.sessions.size }.by 1
    end

    context 'no rtcp_port given' do
      it 'creates a new session with rtcp_port as the next higher port from the rtp port' do
        RTP::Session.should_receive(:new) do |ssrc, ip, rtp, rtcp|
          ssrc.should be > 0
          ip.should == ip
          rtp.should == rtp_port
          rtcp.should == rtcp_port
        end.and_return session

        subject.join_session(ip, rtp_port)
      end
    end

    context 'rtcp_port given' do
      let(:rtcp_port) { 55555 }

      it 'creates a new session with the given rtcp_port' do
        RTP::Session.should_receive(:new) do |ssrc, ip, rtp, rtcp|
          ssrc.should be > 0
          ip.should == ip
          rtp.should == rtp_port
          rtcp.should == rtcp_port
        end.and_return session

        subject.join_session(ip, rtp_port, rtcp_port)
      end
    end

    context 'reactor is not running' do
      before do
        RTP::Session.stub(:new).and_return session
        EM.should_receive(:reactor_running?).and_return false
        session.stub(:start)
      end

      it 'starts the reactor' do
        EM.should_receive(:run)

        subject.join_session(ip, rtp_port)
      end
    end
  end
end
