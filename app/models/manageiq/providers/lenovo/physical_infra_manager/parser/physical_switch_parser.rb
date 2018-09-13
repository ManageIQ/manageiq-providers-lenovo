module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalSwitchParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [XClarityClient::Switch] to a [Hash] with symbols of PhysicalSwitch fields
      PHYSICAL_SWITCH = {
        :name                   => 'name',
        :uid_ems                => 'uuid',
        :switch_uuid            => 'uuid',
        :power_state            => :power_state,
        :type                   => :type,
        :health_state           => :health_state,
        :physical_network_ports => :physical_network_ports,
        :hardware               => {
          :firmwares => :firmwares,
          :networks  => :networks
        },
        :asset_detail           => {
          :product_name           => 'productName',
          :serial_number          => 'serialNumber',
          :part_number            => 'partNumber',
          :field_replaceable_unit => 'FRU',
          :description            => 'description',
          :manufacturer           => 'manufacturer'
        }
      }.freeze

      #
      # Parses a switch into a Hash
      #
      # @param [XClarityClient::Switch] switch - object containing details for the switch
      #
      # @return [Hash] the switch data as required by the application
      #
      def parse_physical_switch(physical_switch)
        parse(physical_switch, PHYSICAL_SWITCH)
      end

      private

      def power_state(switch)
        state = switch.powerState
        if !state.nil? && %w(on off).include?(state.downcase)
          state.downcase
        else
          state
        end
      end

      def type(_switch)
        'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch'
      end

      def health_state(switch)
        HEALTH_STATE_MAP[switch.overallHealthState.nil? ? switch.overallHealthState : switch.overallHealthState.downcase]
      end

      def physical_network_ports(switch)
        parent::PhysicalNetworkPortsParser.parse_physical_switch_ports(switch)
      end

      def firmwares(physical_switch)
        physical_switch.firmware&.map { |firmware| parent::FirmwareParser.parse_firmware(firmware) }
      end

      def networks(physical_switch)
        get_parsed_switch_ip_interfaces_by_key(
          physical_switch.ipInterfaces,
          'IPv4assignments',
          physical_switch.ipv4Addresses,
          false
        ) + get_parsed_switch_ip_interfaces_by_key(
          physical_switch.ipInterfaces,
          'IPv6assignments',
          physical_switch.ipv6Addresses,
          true
        )
      end

      def get_parsed_switch_ip_interfaces_by_key(ip_interfaces, key, address_list, is_ipv6 = false)
        ip_interfaces&.flat_map { |interface| interface[key] }
          .select { |assignment| address_list.include?(assignment['address']) }
          .map { |assignment| parse_network(assignment, is_ipv6) }
      end

      def parse_network(assignment, is_ipv6 = false)
        {
          :subnet_mask     => assignment['subnet'],
          :default_gateway => assignment['gateway'],
          :ipaddress       => (assignment['address'] unless is_ipv6),
          :ipv6address     => (assignment['address'] if is_ipv6)
        }
      end
    end
  end
end
