require 'log_switch'

module RTP
  class Logger
    include LogSwitch
  end
end

RTP::Logger.log_class_name = true
RTP::Logger.logging_enabled = false

