module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    include ::EmsRefresh::Refreshers::EmsRefresherMixin

    def parse_legacy_inventory(ems)
      $log.info("MIQ_LENOVO(#{self.class.name}.#{__method__} Calling for [#{ems.name}])")

      # Update EMS references
      ems.update_ipaddress
      ems.update_hostname

      # Perform a full fetch of the EMS inventory
      log_header = "Collecting data for EMS : [#{ems.name}] id: [#{ems.id} ref: #{ems.uid_ems}]"
      $log.info("#{log_header}...")
      inventory = PhysicalInfraManager::RefreshParser.new(ems.connection).ems_inv_to_hashes
      $log.info("#{log_header}...Complete")

      inventory
    end
  end
end
