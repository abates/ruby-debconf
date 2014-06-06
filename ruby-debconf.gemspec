# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby/debconf/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-debconf"
  spec.version       = Ruby::Debconf::VERSION
  spec.authors       = ["Andrew Bates"]
  spec.email         = ["abates@omeganetserv.com"]
  spec.description   = %q{Simple Ruby interface to debconf}
  spec.summary       = %q{}
  spec.homepage      = "http://github.com/abates/ruby-debconf"
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
