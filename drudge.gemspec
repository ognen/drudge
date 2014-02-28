# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drudge/version'

Gem::Specification.new do |spec|
  spec.name          = "drudge"
  spec.version       = Drudge::VERSION
  spec.authors       = ["Ognen Ivanovski"]
  spec.email         = ["ognen.ivanovski@me.com"]
  spec.description   = %q{A library for building command-line
                          automation tools with the aim of transferring you (conceptionally) from the command line
                          interface into Ruby and then letting you use build your tool in a familiar
                          environement.}
  spec.summary       = %q{A gem that enables you to write command line automation tools using Ruby 2.0.}
  spec.homepage      = "https://github.com/ognen/drudge"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.0.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", ">= 2.14", "< 3.0"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "aruba", ">= 0.4.6"
  spec.add_development_dependency "yard", ">= 0.8.6.1"
  spec.add_development_dependency "gem-release" 

end
