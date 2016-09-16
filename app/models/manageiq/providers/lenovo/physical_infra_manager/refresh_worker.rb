class ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshWorker < ::MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::Lenovo::PhysicalInfraManager
  end

  def self.settings_name
    :ems_refresh_worker_lenovo_physical_infra
  end

end
