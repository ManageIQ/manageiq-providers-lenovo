module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalSwitch < ::PhysicalSwitch
    include_concern 'Operations'

    def self.display_name(number = 1)
      n_('Physical Switch (Lenovo)', 'Physical Switches (Lenovo)', number)
    end
  end
end
