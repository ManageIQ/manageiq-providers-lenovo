module ManageIQ::Providers::Lenovo
  # dictionary homologated for versions:
  # 1.3
  class ParserDictionaryConstants
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
    PHYSICAL_SERVER = {
      :name                   => 'name',
      :ems_ref                => 'uuid',
      :uid_ems                => 'uuid',
      :hostname               => 'hostname',
      :product_name           => 'productName',
      :manufacturer           => 'manufacturer',
      :machine_type           => 'machineType',
      :model                  => 'model',
      :serial_number          => 'serialNumber',
      :field_replaceable_unit => 'FRU',
      :asset_details          => {
        :contact          => 'contact',
        :description      => 'description',
        :location         => 'location.location',
        :room             => 'location.room',
        :rack_name        => 'location.rack',
        :lowest_rack_unit => 'location.lowestRackUnit'
      },
      :computer_system        => {
        :hardware => {
          :guest_devices => '',
          :firmwares     => ''
        },
      },
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
