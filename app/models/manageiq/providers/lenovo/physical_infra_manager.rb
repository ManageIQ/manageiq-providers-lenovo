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

  # Asset details
  has_many :physical_server_details,  :through => :physical_servers,  :source => :asset_detail
  has_many :physical_chassis_details, :through => :physical_chassis,  :source => :asset_detail
  has_many :physical_storage_details, :through => :physical_storages, :source => :asset_detail
  has_many :physical_switch_details,  :through => :physical_switches, :source => :asset_detail

  # Computer systems
  has_many :physical_server_computer_systems,  :through => :physical_servers,  :source => :computer_system
  has_many :physical_chassis_computer_systems, :through => :physical_chassis,  :source => :computer_system
  has_many :physical_storage_computer_systems, :through => :physical_storages, :source => :canister_computer_systems

  # Hardwares
  has_many :physical_server_hardwares,  :through => :physical_server_computer_systems,  :source => :hardware
  has_many :physical_chassis_hardwares, :through => :physical_chassis_computer_systems, :source => :hardware
  has_many :physical_storage_hardwares, :through => :physical_storage_computer_systems, :source => :hardware
  has_many :physical_switch_hardwares,  :through => :physical_switches, :source => :hardware

  # Guest devices
  has_many :physical_server_network_devices,     :through => :physical_server_hardwares,  :source => :nics
  has_many :physical_server_storage_adapters,    :through => :physical_server_hardwares,  :source => :storage_adapters
  has_many :physical_server_management_devices,  :through => :physical_server_hardwares,  :source => :management_devices
  has_many :physical_chassis_management_devices, :through => :physical_chassis_hardwares, :source => :management_devices
  has_many :physical_storage_management_devices, :through => :physical_storage_hardwares, :source => :management_devices

  # Firmwares
  has_many :physical_server_firmwares,                 :through => :physical_server_hardwares,        :source => :firmwares
  has_many :physical_server_network_device_firmwares,  :through => :physical_server_network_devices,  :source => :firmwares
  has_many :physical_server_storage_adapter_firmwares, :through => :physical_server_storage_adapters, :source => :firmwares
  has_many :physical_switch_firmwares,                 :through => :physical_switch_hardwares,        :source => :firmwares
  has_many :physical_storage_firmwares,                :through => :physical_storage_hardwares,       :source => :firmwares

  # Network
  has_many :physical_server_networks,  :through => :physical_server_management_devices,  :source => :network
  has_many :physical_chassis_networks, :through => :physical_chassis_management_devices, :source => :network
  has_many :physical_storage_networks, :through => :physical_storage_management_devices, :source => :network
  has_many :physical_switch_networks,  :through => :physical_switch_hardwares,           :source => :networks

  # Physical network ports
  has_many :physical_server_network_ports, :through => :physical_server_network_devices,     :source => :physical_network_ports
  has_many :physical_switch_network_ports, :through => :physical_switches,                    :source => :physical_network_ports
  has_many :physical_storage_network_ports, :through => :physical_storage_management_devices, :source => :physical_network_ports

  # Physical disks
  has_many :physical_disks, :through => :physical_storages

  # Canisters
  has_many :canisters, :through => :physical_storages


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
