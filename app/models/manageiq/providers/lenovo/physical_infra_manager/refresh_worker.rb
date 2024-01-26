class ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshWorker < ::MiqEmsRefreshWorker
  def self.settings_name
    :ems_refresh_worker_lenovo_physical_infra
  end
end
