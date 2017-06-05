module ManageIQ
  module Providers
    module Nuage
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Nuage
      end
    end
  end
end
