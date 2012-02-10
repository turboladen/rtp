require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w(-w)
  t.rspec_opts = %w(--format documentation --color)
end

RSpec::Core::RakeTask.new(:spec_html) do |t|
  t.rspec_opts = %w(--format html --out rspec_output.html)
end
