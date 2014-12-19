# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'attachments/version'

Gem::Specification.new do |spec|
  spec.name          = "attachments"
  spec.version       = Attachments::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@plainpicture.de"]
  spec.summary       = %q{Declarative and flexible attachments}
  spec.description   = %q{Declarative and flexible attachments}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
