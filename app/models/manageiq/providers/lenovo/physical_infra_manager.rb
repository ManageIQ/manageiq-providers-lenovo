class ManageIQ::Providers::Lenovo::PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
  include ManageIQ::Providers::Lenovo::ManagerMixin
  include_concern 'Operations'
  include_concern 'AuthenticatableProvider'

  require_nested :Refresher
  require_nested :RefreshParser
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Parser
  require_nested :RefreshWorker

  require_nested :Firmware
  require_nested :Hardware
  require_nested :PhysicalChassis
  require_nested :PhysicalRack
  require_nested :PhysicalServer
  require_nested :PhysicalStorage
  require_nested :PhysicalSwitch

  supports :change_password

  def self.ems_type
    @ems_type ||= "lenovo_ph_infra".freeze
  end

  def self.description
    @description ||= "Lenovo XClarity"
  end

  def supports_provisioning?
    true
  end
end
