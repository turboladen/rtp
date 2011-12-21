$:.push File.expand_path("../lib", __FILE__)
require 'rtp/version'

Gem::Specification.new do |s|
  s.name = "rtp"
  s.version = RTP::VERSION
  s.authors = ["Steve Loveless"]
  s.homepage = %q(http://github.com/turboladen/rtp)
  s.email = %w(steve.loveless@gmail.com)
  s.description = %q(FIX)
  s.summary = %q(FIX)

  s.required_rubygems_version = ">=1.8.0"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.executables = ["rtp"]
  s.files = Dir.glob("{lib,spec,tasks}/**/*") + Dir.glob("*.rdoc") +
    %w(.gemtest Gemfile rtp.gemspec Rakefile)
  s.test_files = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]

  s.add_dependency("bindata", [">= 0"])
  s.add_dependency("log_switch", ">=0")

  s.add_development_dependency("bundler", [">= 0"])
  s.add_development_dependency("code_statistics", ["~> 0.2.13"])
  s.add_development_dependency("metric_fu", [">= 2.0.1"])
  s.add_development_dependency("rake", [">= 0"])
  s.add_development_dependency("rspec", ["~> 2.7.0"])
  s.add_development_dependency("simplecov", [">= 0"])
  s.add_development_dependency("simplecov-rcov-text", [">= 0"])
  s.add_development_dependency("yard", [">= 0.7.2"])
end
