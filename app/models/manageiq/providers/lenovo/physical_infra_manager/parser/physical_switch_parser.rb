module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalSwitchParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # Parses a switch into a Hash
      #
      # @param [XClarityClient::Switch] switch - object containing details for the switch
      #
      # @return [Hash] the switch data as required by the application
      #
      def parse_physical_switch(physical_switch)
        result = parse(physical_switch, parent::ParserDictionaryConstants::PHYSICAL_SWITCH)

        unless result[:power_state].nil?
          result[:power_state] = result[:power_state].downcase if %w(on off).include?(result[:power_state].downcase)
        end
        result[:type]         = parent::ParserDictionaryConstants::MIQ_TYPES["physical_switch"]
        result[:health_state] = parent::ParserDictionaryConstants::HEALTH_STATE_MAP[physical_switch.overallHealthState.nil? ? physical_switch.overallHealthState : physical_switch.overallHealthState.downcase]
        result[:hardware]     = get_hardwares(physical_switch)

        result[:physical_network_ports] = parent::PhysicalNetworkPortsParser.parse_physical_switch_ports(physical_switch)

        result
      end

      private

      def get_hardwares(physical_switch)
        {
          :firmwares     => get_firmwares(physical_switch),
          :networks      => get_networks(physical_switch)
        }
      end

      def get_networks(physical_switch)
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
        result = parse(assignment, parent::ParserDictionaryConstants::PHYSICAL_SWITCH_NETWORK)

        result[:ipaddress]   = assignment['address'] unless is_ipv6
        result[:ipv6address] = assignment['address'] if is_ipv6

        result
      end

      def get_firmwares(physical_switch)
        physical_switch.firmware&.map { |firmware| parent::FirmwareParser.parse_firmware(firmware) }
      end
    end
  end
end
