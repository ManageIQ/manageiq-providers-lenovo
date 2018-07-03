module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalChassis < ::PhysicalChassis
    include_concern 'Operations'

    def self.display_name(number = 1)
      n_('Physical Chassis (Lenovo)', 'Physical Chassis (Lenovo)', number)
    end
  end
end
