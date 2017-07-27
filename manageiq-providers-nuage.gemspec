$:.push File.expand_path("../lib", __FILE__)

require "manageiq/providers/nuage/version"

Gem::Specification.new do |s|
  s.name        = "manageiq-providers-nuage"
  s.version     = ManageIQ::Providers::Nuage::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-providers-nuage"
  s.summary     = "Nuage Provider for ManageIQ"
  s.description = "Nuage Provider for ManageIQ"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,config,lib}/**/*"]

  s.add_runtime_dependency "excon", "~>0.40"

  s.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  s.add_development_dependency "simplecov"
end
