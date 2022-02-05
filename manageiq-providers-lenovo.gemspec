# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/lenovo/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-lenovo"
  spec.version       = ManageIQ::Providers::Lenovo::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ plugin for the Lenovo XClarity provider."
  spec.description   = "ManageIQ plugin for the Lenovo XClarity provider."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-lenovo"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "xclarity_client", "~> 0.6.0"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
