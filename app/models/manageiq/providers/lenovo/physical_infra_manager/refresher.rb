module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def parse_legacy_inventory(ems)
      ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end

    def save_inventory(ems, target, hashes)
      EmsRefresh.save_ems_inventory(ems, hashes)
    end

    def post_process_refresh_classes
      []
    end

  end
end
