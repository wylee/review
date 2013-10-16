# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'review/version'

Gem::Specification.new do |spec|
  spec.name          = "review"
  spec.version       = Review::VERSION
  spec.authors       = ["Wyatt Lee Baldwin"]
  spec.email         = ["wyatt.lee.baldwin@gmail.com"]
  spec.description   = "Simple GitHub code review tool"
  spec.summary       = ""
  spec.homepage      = "https://github.com/wylee/review"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "octokit"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
