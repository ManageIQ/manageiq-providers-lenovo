module ManageIQ
  module Providers
    module Lenovo
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Lenovo

        def self.plugin_name
          _('Lenovo Provider')
        end
      end
    end
  end
end
