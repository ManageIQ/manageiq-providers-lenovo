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

  supports :change_password

  def self.ems_type
    @ems_type ||= "lenovo_ph_infra".freeze
  end

  def self.description
    @description ||= "Lenovo XClarity"
  end

  # Returns a new connection to the LXCA
  def connection
    connect(:user => authentications.first.userid,
            :pass => authentications.first.password,
            :host => endpoints.first.hostname,
            :port => endpoints.first.port)
  end
end
