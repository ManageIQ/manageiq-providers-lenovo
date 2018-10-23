module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::PhysicalChassis < Inventory::Parser::ComponentParser
    # Mapping between fields inside a [XClarity:PhysicalChassis] to a [Hash] with symbols of PhysicalChassis fields
    PHYSICAL_CHASSIS = {
      :name                         => 'name',
      :uid_ems                      => 'uuid',
      :ems_ref                      => 'uuid',
      :overall_health_state         => 'overallHealthState',
      :management_module_slot_count => 'mmSlots',
      :switch_slot_count            => 'switchSlots',
      :fan_slot_count               => 'fanSlots',
      :blade_slot_count             => 'bladeSlots',
      :powersupply_slot_count       => 'powerSupplySlots',
      :vendor                       => :vendor,
      # :type                         => :type,
      :health_state                 => :health_state,
      :computer_system              => {
        :hardware => {
          :guest_devices => nil, #:guest_devices
        }
      },
      :asset_detail                 => {
        :product_name     => 'productName',
        :manufacturer     => 'manufacturer',
        :machine_type     => 'machineType',
        :model            => 'model',
        :serial_number    => 'serialNumber',
        :contact          => 'contact',
        :description      => 'description',
        :location         => 'location.location',
        :room             => 'location.room',
        :rack_name        => 'location.rack',
        :lowest_rack_unit => 'location.lowestRackUnit'
      }
    }.freeze

    #
    # @param [Hash] chassis_hash - hash containing physical chassis raw data
    # @param [InventoryObject] rack - parsed physical rack data
    #
    def build(chassis_hash, rack)
      chassis_xclarity, properties = parse_physical_chassis(chassis_hash)

      add_parent(properties, :belongs_to => :physical_rack, :object => rack) if rack

      chassis = @persister.physical_chassis.build(properties)

      build_associations(chassis, chassis_xclarity)

      chassis
    end

    #
    # Parse a chassis hash to a hash with physical racks data
    #
    # @param [Hash] chassis_hash - hash containing physical chassis raw data
    #
    # @return [Hash] containing the physical server information
    #
    def parse_physical_chassis(chassis_hash)
      chassis = XClarityClient::Chassi.new(chassis_hash)
      result = parse(chassis, PHYSICAL_CHASSIS)

      [chassis, result]
    end

    private

    def build_associations(chassis, chassis_xclarity)
      comp_system = build_computer_system(chassis)
      build_hardware(comp_system, chassis_xclarity)
      build_asset_detail(chassis, chassis_xclarity)
    end

    def build_hardware(comp_system, chassis_xclarity)
      hw = @persister.physical_chassis_hardwares.build(
        :computer_system => comp_system
      )

      build_guest_devices(hw, chassis_xclarity)
    end

    def build_guest_devices(hardware, chassis_xclarity)
      components(:management_devices).build(chassis_xclarity,
                                            :physical_chassis_management_devices,
                                            :belongs_to => :hardware,
                                            :object     => hardware)
    end

    def build_asset_detail(hardware, chassis_xclarity)
      super(hardware, chassis_xclarity, PHYSICAL_CHASSIS[:asset_detail]) do |properties|
        properties.merge!(get_location_led_info(chassis_xclarity.leds) || {})
      end
    end

    def vendor(_chassis)
      'lenovo'
    end

    def type(_chassis)
      'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis'
    end

    def health_state(chassis)
      HEALTH_STATE_MAP[chassis.cmmHealthState.nil? ? chassis.cmmHealthState : chassis.cmmHealthState.downcase]
    end
  end
end
