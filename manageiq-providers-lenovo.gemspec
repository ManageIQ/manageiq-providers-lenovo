$:.push File.expand_path("../lib", __FILE__)

require "manageiq/providers/lenovo/version"

Gem::Specification.new do |s|
  s.name        = "manageiq-providers-lenovo"
  s.version     = ManageIQ::Providers::Lenovo::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-providers-lenovo"
  s.summary     = "Lenovo XClarity Provider for ManageIQ"
  s.description = "Lenovo XClarity Provider for ManageIQ"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,config.lib}/**/*"]

  s.add_dependency "xclarity_client", "~> 0.3.1"
end
