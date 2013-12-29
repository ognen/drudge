require 'cucumber'
require 'aruba/cucumber'
require 'rspec/expectations'

ENV['PATH'] = "#{File.expand_path '../../tmp/aruba', __dir__}#{File::PATH_SEPARATOR}#{ENV['PATH']}"