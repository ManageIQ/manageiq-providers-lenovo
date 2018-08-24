module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalChassisParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
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
        result = parse(chassis, parent::ParserDictionaryConstants::PHYSICAL_CHASSIS)

        result[:physical_rack]                       = rack if rack
        result[:vendor]                              = "lenovo"
        result[:type]                                = MIQ_TYPES["physical_chassis"]
        result[:health_state]                        = HEALTH_STATE_MAP[chassis.cmmHealthState.nil? ? chassis.cmmHealthState : chassis.cmmHealthState.downcase]
        result[:computer_system][:hardware]          = get_hardwares(chassis)

        result[:asset_detail].merge!(get_location_led_info(chassis.leds))

        result
      end

      private

      def get_hardwares(chassis)
        parsed_chassi_network = parse(chassis, parent::ParserDictionaryConstants::PHYSICAL_CHASSIS_NETWORK)

        {
          :guest_devices => [{
            :device_type => "management",
            :network     => parsed_chassi_network
          }]
        }
      end
    end
  end
end
