require 'log_switch'

module RTP
  class Logger
    extend LogSwitch
  end
end

RTP::Logger.log_class_name = true
