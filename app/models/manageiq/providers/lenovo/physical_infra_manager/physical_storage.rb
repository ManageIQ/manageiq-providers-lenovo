module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalStorage < ::PhysicalStorage
    def self.display_name(number = 1)
      n_('Physical Storage (Lenovo)', 'Physical Storages (Lenovo)', number)
    end
  end
end
