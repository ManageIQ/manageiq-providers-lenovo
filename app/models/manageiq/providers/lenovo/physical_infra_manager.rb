class ManageIQ::Providers::Lenovo::PhysicalInfraManager < ManageIQ::Providers::InfraManager
  include ManageIQ::Providers::Lenovo::ManagerMixin

  require_nested :Refresher
  require_nested :RefreshParser
#  require_nested :RefreshWorker

  def self.ems_type
    @ems_type ||= "lenovo_ph_infra".freeze
  end

  def self.description
    @description ||= "Lenovo XClarity"
  end
end
