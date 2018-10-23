module ManageIQ::Providers::Lenovo
  #
  # Superclass extended by all classes that parses LXCA component_parser
  # to a MiQ format
  #
  class Inventory::Parser::ComponentParser
    require_nested :Canister
    require_nested :CompliancePolicy
    require_nested :ComputerSystem
    require_nested :ConfigPattern
    require_nested :Firmware
    require_nested :GuestDevice
    require_nested :ManagementDevice
    require_nested :NetworkDevice
    require_nested :PhysicalDisk
    require_nested :PhysicalChassis
    require_nested :PhysicalNetworkPort
    require_nested :PhysicalRack
    require_nested :PhysicalServer
    require_nested :PhysicalStorage
    require_nested :PhysicalSwitch
    require_nested :StorageDevice

    attr_reader :persister, :parser

    delegate :components,
             :to => :parser

    HEALTH_STATE_MAP = {
      'normal'          => 'Valid',
      'non-critical'    => 'Valid',
      'warning'         => 'Warning',
      'critical'        => 'Critical',
      'unknown'         => 'None',
      'minor-failure'   => 'Critical',
      'major-failure'   => 'Critical',
      'non-recoverable' => 'Critical',
      'fatal'           => 'Critical',
      nil               => 'Unknown'
    }.freeze

    POWER_STATE_MAP = {
      8  => 'On',
      5  => 'Off',
      18 => 'Standby',
      0  => 'Unknown'
    }.freeze

    PROPERTIES_MAP = {
      :led_identify_name => %w(Identification Identify Location),
    }.freeze

    private_constant :HEALTH_STATE_MAP
    private_constant :POWER_STATE_MAP
    private_constant :PROPERTIES_MAP

    def initialize(persister, parser)
      @persister = persister
      @parser    = parser
    end

    #
    # Returns a hash containing the structure described on dictionary
    # and with the values in the source.
    #
    # @param source     - Object that will be parse to a hash
    # @param dictionary - Hash containing the instructions to translate the object into a Hash
    #
    def parse(source, dictionary)
      result = {}
      dictionary&.each do |key, value|
        if value.kind_of?(String)
          next if value.empty?
          source_keys = value.split('.') # getting source keys navigation
          source_value = source
          source_keys.each do |source_key|
            begin
              attr_method = source_value.method(source_key) # getting method to get the attribute value
              source_value = attr_method.call
            rescue NameError
              # when the key doesn't correspond to a method
              source_value = source_value[source_key]
            end
          end
          result[key] = source_value.kind_of?(String) ? source_value.strip.presence : source_value
        elsif value.kind_of?(Symbol)
          result[key] = send(value, source)
        end
      end
      result
    end

    def get_location_led_info(leds)
      return if leds.blank?
      identification_led = leds.to_a.find { |led| PROPERTIES_MAP[:led_identify_name].include?(led["name"]) }

      {
        :location_led_ems_ref => identification_led.try(:[], "name"),
        :location_led_state   => identification_led.try(:[], "state")
      }
    end

    protected

    # Adds parent InventoryObject to properties
    #
    # @param properties [Hash]
    # @param parent [Hash] :belongs_to => <Symbol>, :object => <InventoryObject>
    def add_parent(properties, parent)
      properties[parent[:belongs_to]] = parent[:object]
    end

    def build_computer_system(parent_object)
      components(:computer_systems).build(:belongs_to => :managed_entity,
                                          :object     => parent_object)
    end

    def build_asset_detail(inventory_object, xclarity_object, properties)
      properties = parse(xclarity_object, properties)

      yield properties if block_given?

      add_parent(properties, :belongs_to => :resource, :object => inventory_object)

      parent_collection_name = inventory_object&.inventory_collection&.association
      inventory_collection_name = case parent_collection_name
                                  when :physical_servers then :physical_server_details
                                  when :physical_chassis then :physical_chassis_details
                                  when :physical_storages then :physical_storage_details
                                  when :physical_switches then :physical_switch_details
                                  else raise "Unknown parent inventory collection (#{parent_collection_name})"
                                  end
      @persister.send(inventory_collection_name).build(properties)
    end
  end
end
