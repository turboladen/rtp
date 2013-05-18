# Media files found in support/ came from
# http://support.apple.com/kb/HT1425?viewlocale=en_US&locale=en_US
require 'simplecov'

SimpleCov.start do
  add_group 'Lib', 'lib' do |src_file|
    src_file.filename !~ /spec/
  end

  add_group 'Specs', 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
