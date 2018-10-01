module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'RemoteConsole'
    include_concern 'Operations'

    def self.display_name(number = 1)
      n_('Physical Server (Lenovo)', 'Physical Servers (Lenovo)', number)
    end
  end
end
