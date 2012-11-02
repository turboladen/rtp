require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

# Load all extra rake task definitions
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |ext| load ext }


YARD::Rake::YardocTask.new
RSpec::Core::RakeTask.new

# Alias for rubygems-test
task test: :spec
task default: :test
