module ManageIQ::Providers::Lenovo
  # dictionary homologated for versions:
  # 1.3
  class PhysicalInfraManager::Parser::ParserDictionaryConstants
    POWER_STATE_MAP = {
      8  => "on",
      5  => "off",
      18 => "Standby",
      0  => "Unknown"
    }.freeze

    HEALTH_STATE_MAP = {
      "normal"          => "Valid",
      "non-critical"    => "Valid",
      "warning"         => "Warning",
      "critical"        => "Critical",
      "unknown"         => "None",
      "minor-failure"   => "Critical",
      "major-failure"   => "Critical",
      "non-recoverable" => "Critical",
      "fatal"           => "Critical",
      nil               => "Unknown"
    }.freeze

    MIQ_TYPES = {
      "physical_server" => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer",
      "physical_switch" => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch",
      "template"        => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template",
    }.freeze

    PROPERTIES_MAP = {
      :led_identify_name => %w(Identification Identify)
    }.freeze

    # TRANSLATE HASHES BEGIN
    # The translate hashes are used to parse an object to a hash
    # where the translate hash keys are set as object hash keys
    # and your values (string) corresponds to the attributes of the
    # source object who the value will be set as value of the key of result hash.
    # see +ManageIQ::Providers::Lenovo::Parse#parse+
    PHYSICAL_SWITCH = {
      :name         => 'name',
      :uid_ems      => 'uuid',
      :switch_uuid  => 'uuid',
      :power_state  => 'powerState',
      :asset_detail => {
        :product_name  => 'productName',
        :serial_number => 'serialNumber',
        :description   => 'description',
        :manufacturer  => 'manufacturer',
      },
    }.freeze

    PHYSICAL_SWITCH_NETWORK = {
      :subnet_mask     => 'subnet',
      :default_gateway => 'gateway',
    }.freeze

    PHYSICAL_SERVER = {
      :name            => 'name',
      :ems_ref         => 'uuid',
      :uid_ems         => 'uuid',
      :hostname        => 'hostname',
      :asset_detail    => {
        :product_name           => 'productName',
        :manufacturer           => 'manufacturer',
        :machine_type           => 'machineType',
        :model                  => 'model',
        :serial_number          => 'serialNumber',
        :part_number            => 'partNumber',
        :field_replaceable_unit => 'FRU',
        :contact                => 'contact',
        :description            => 'description',
        :location               => 'location.location',
        :room                   => 'location.room',
        :rack_name              => 'location.rack',
        :lowest_rack_unit       => 'location.lowestRackUnit'
      },
      :computer_system => {
        :hardware => {
          :guest_devices => '',
          :firmwares     => ''
        },
      },
    }.freeze

    PHYSICAL_RACK = {
      :name    => 'cabinetName',
      :uid_ems => 'UUID',
      :ems_ref => 'UUID',
    }.freeze

    CONFIG_PATTERNS = {
      :manager_ref  => 'id',
      :name         => 'name',
      :description  => 'description',
      :user_defined => 'userDefined',
      :in_use       => 'inUse'
    }.freeze
    # TRANSLATE HASH END
  end
end
