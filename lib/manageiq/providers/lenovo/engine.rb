module ManageIQ
  module Providers
    module Lenovo
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Lenovo
      end
    end
  end
end
