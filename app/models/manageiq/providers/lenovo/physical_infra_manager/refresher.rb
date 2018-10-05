module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Refresher < ManageIQ::Providers::BaseManager::ManagerRefresher
    def parse_legacy_inventory(ems)
      $log.info("MIQ_LENOVO(#{self.class.name}.#{__method__} Calling for [#{ems.name}])")

      ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser.ems_inv_to_hashes(ems, refresher_options)
    end
  end
end
