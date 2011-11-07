require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = "-w"
  t.rspec_opts = ['--format', 'documentation', '--color']
end

RSpec::Core::RakeTask.new(:spec_html) do |t|
  t.rspec_opts = ['--format', 'html', '--out', 'rspec_output.html']
end
