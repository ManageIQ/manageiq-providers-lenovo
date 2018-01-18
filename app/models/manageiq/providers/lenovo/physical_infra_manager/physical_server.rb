module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'RemoteConsole'

    def self.display_name(number = 1)
      n_('Physical Server (Lenovo)', 'Physical Servers (Lenovo)', number)
    end
  end
end
