module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalSwitch < ::PhysicalSwitch
    include_concern 'Operations'
  end
end
