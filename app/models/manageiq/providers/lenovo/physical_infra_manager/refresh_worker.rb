class ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::Lenovo::PhysicalInfraManager
  end

end
