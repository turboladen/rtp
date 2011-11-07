require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'yard'

# Load all extra rake task definitions
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |ext| load ext }

task default: :install

YARD::Rake::YardocTask.new
Cucumber::Rake::Task.new(:features)
RSpec::Core::RakeTask.new

# Alias for rubygems-test
task test: :spec

