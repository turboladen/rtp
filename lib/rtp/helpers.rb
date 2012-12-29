module RTP
  module Helpers
    def mac?
      !!RUBY_VERSION =~ /darwin/
    end

    def win?
      !!RUBY_PLATFORM =~ /mswin|mingw/
    end

    def linux?
      !!RUBY_PLATFORM =~ /linux/
    end
  end
end
