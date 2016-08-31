module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def parse_legacy_inventory(ems)
      ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end

    def save_inventory(ems, target, hashes)
      EmsRefresh.save_ems_inventory(ems, hashes)
    end

  end
end
