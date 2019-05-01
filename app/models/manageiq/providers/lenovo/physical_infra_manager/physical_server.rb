module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'RemoteConsole'
    include_concern 'Operations'
    include_concern 'Provisioning'

    def self.display_name(number = 1)
      n_('Physical Server (Lenovo)', 'Physical Servers (Lenovo)', number)
    end

    def provider_object(connection)
    	#connection.find(ems_ref)
      return connection
    end
  end
end
