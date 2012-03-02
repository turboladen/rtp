Feature: Receives Data
  As an RTP consumer, I want to be able to receive RTP data over a socket
  so that I can consume the A/V information delivered in the RTP packets.

  Scenario: Receiver returns true while it's running
    Given an RTP::Receiver is runing
    When I call #running?
    Then it returns true
