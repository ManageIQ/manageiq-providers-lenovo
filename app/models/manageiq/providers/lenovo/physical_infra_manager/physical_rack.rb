module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalRack < ::PhysicalRack
    def self.display_name(number = 1)
      n_('Physical Rack (Lenovo)', 'Physical Racks (Lenovo)', number)
    end
  end
end
