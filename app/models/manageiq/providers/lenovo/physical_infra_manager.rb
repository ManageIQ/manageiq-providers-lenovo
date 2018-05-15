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
    self.connect(:user => authentications.first.userid,
                 :pass => authentications.first.password,
                 :host => endpoints.first.hostname,
                 :port => endpoints.first.port)
  end

  # Updates the value of the ipaddress if only a hostname was given
  def update_ipaddress
    if @ipaddress.blank?
      host = host_or_ipaddress
      @ipaddress = Resolv.getaddress(host)
      $log.info("EMS ID: #{@id}" + " Resolved ip address successfully.")
    end
  rescue StandardError => err
    $log.warn("EMS ID: #{@id}" + " It's not possible resolve ip address of the physical infra, #{err}.")
  end
 
  # Updates the value of the hostname if only an ipaddress was given
  def update_hostname
    ipaddress = host_or_ipaddress
    if IPAddr.new(ipaddress)
      @hostname = Resolv.getname(ipaddress)
      $log.info("EMS ID: #{@id}" + " Resolved hostname successfully.")
    end
  rescue StandardError => err
    $log.warn("EMS ID: #{@id}" + " It's not possible resolve hostname of the physical infra, #{err}.")
  end
 
  private
 
  # Gets the current value of the hostname field without schema parts (can be a hostname or just an IP address)
  def host_or_ipaddress
    URI.parse(@hostname).host || URI.parse(@hostname).path
  end
end
