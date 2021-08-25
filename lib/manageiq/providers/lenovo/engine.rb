module ManageIQ
  module Providers
    module Lenovo
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Lenovo

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Lenovo Provider')
        end

        def self.init_loggers
          $lenovo_log ||= Vmdb::Loggers.create_logger("lenovo.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $lenovo_log, :level_lenovo)
        end
      end
    end
  end
end
