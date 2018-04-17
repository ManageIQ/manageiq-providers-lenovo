module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'RemoteConsole'
  end
end
