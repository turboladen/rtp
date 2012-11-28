require 'simplecov'

SimpleCov.start do
  add_group "Lib", "lib" do |src_file|
    src_file.filename !~ /spec/
  end

  add_group "Specs", "spec"
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
