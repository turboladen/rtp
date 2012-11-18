require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

# Load all extra rake task definitions
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |ext| load ext }


YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/**/*.rb - *.rdoc)
  t.options = %w[--private --protected --verbose]
end

RSpec::Core::RakeTask.new do |t|
  t.ruby_opts = %w[-w]
end

# Alias for rubygems-test
task test: :spec
task default: :test
