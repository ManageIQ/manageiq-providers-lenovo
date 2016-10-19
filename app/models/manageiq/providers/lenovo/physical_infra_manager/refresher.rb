module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    
    def parse_legacy_inventory(ems)

      log_header = "MIQ_LENOVO(#{self.class.name}.#{__method__} Calling for [#{ems.name}])"
      $log.info("#{log_header}")
    
      #TODO the following call isn't working
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
