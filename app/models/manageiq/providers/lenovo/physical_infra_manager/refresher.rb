module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def parse_legacy_inventory(ems)

      log_header = "MIQ_LENOVO(#{self.class.name}.#{__method__} Calling for [#{ems.name}])"
      $log.info("#{log_header}")

      # Update EMS references
      ems.update_ipaddress
      ems.update_hostname

      ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end
  end
end
