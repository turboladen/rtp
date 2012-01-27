$:.push File.expand_path("../lib", __FILE__)
require 'rtp/version'

Gem::Specification.new do |s|
  s.name = "rtp"
  s.version = RTP::VERSION
  s.author = "Steve Loveless"
  s.homepage = %q(http://github.com/turboladen/rtp)
  s.email = %w(steve.loveless@gmail.com)
  s.description = %q(This is a pure Ruby implementation of RTP, initially geared
  towards use with RTSP (but not limited to).)
  s.summary = %q(Pure Ruby implementation of RTP)

  s.required_rubygems_version = ">=1.8.0"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.files = Dir.glob("{lib,spec,tasks}/**/*") + Dir.glob("*.rdoc") +
    %w(.gemtest Gemfile rtp.gemspec Rakefile)
  s.test_files = Dir.glob("spec/**/*")
  s.require_paths = %w(lib)

  s.add_dependency("bindata", "~> 1.4")
  s.add_dependency("log_switch", ">=0.2.0")

  s.add_development_dependency("bundler", ">= 0")
  s.add_development_dependency("rake", ">= 0")
  s.add_development_dependency("rspec", "~> 2.7")
  s.add_development_dependency("simplecov", ">= 0")
  s.add_development_dependency("simplecov-rcov-text", ">= 0")
  s.add_development_dependency("yard", ">= 0.7.2")
end
