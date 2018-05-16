module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalChassisParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
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
        :type                         => :type,
        :health_state                 => :health_state,
        :location_led_state           => :location_led_state,
        :computer_system              => {
          :hardware => {
            :guest_devices => :guest_devices,
          },
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
          :lowest_rack_unit => 'location.lowestRackUnit',
        },
      }.freeze

      #
      # Parse a chassis hash to a hash with physical racks data
      #
      # @param [Hash] chassis_hash - hash containing physical chassis raw data
      # @param [Hash] rack - parsed physical rack data
      #
      # @return [Hash] containing the physical server information
      #
      def parse_physical_chassis(chassis_hash, rack)
        chassis = XClarityClient::Chassi.new(chassis_hash)
        result = parse(chassis, PHYSICAL_CHASSIS)

        result[:physical_rack] = rack if rack
        result
      end

      private

      def vendor(_chassis)
        'lenovo'
      end

      def type(_chassis)
        'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis'
      end

      def health_state(chassis)
        HEALTH_STATE_MAP[chassis.cmmHealthState.nil? ? chassis.cmmHealthState : chassis.cmmHealthState.downcase]
      end

      def location_led_state(chassis)
        identification_led = chassis.leds.to_a.find { |led| PROPERTIES_MAP[:led_identify_name].include?(led['name']) }
        identification_led.try(:[], 'state')
      end

      def guest_devices(chassis)
        [{
          :device_type => 'management',
          :network     => {
            :ipaddress => chassis.mgmtProcIPaddress
          }
        }]
      end
    end
  end
end
