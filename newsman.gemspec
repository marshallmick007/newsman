# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newsman/version'

Gem::Specification.new do |spec|
  spec.name          = "newsman"
  spec.version       = Newsman::VERSION
  spec.authors       = ["Marshall Mickelson"]
  spec.email         = ["marshallmick+git@gmail.com"]
  spec.summary       = %q{Find and Fetch RSS and ATOM feeds}
  spec.description   = %q{Find and Fetch RSS and ATOM feeds}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "awesome_print", "~> 1.7.0"

  spec.add_dependency "nokogiri", "~> 1.8.0"
  spec.add_dependency "sanitize", "~> 2.1.0"
  spec.add_dependency "open_uri_redirections", "~> 0.2.1"
end
