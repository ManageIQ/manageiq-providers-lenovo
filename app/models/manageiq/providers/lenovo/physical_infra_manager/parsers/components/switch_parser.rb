require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class SwitchParser < ComponentParser
      class << self
        #
        # Parses a switch into a Hash
        #
        # @param [XClarityClient::Switch] switch - object containing details for the switch
        #
        # @return [Hash] the switch data as required by the application
        #
        def parse_switch(switch)
          result = parse(switch, ParserDictionaryConstants::SWITCH)

          result[:type]     = ParserDictionaryConstants::MIQ_TYPES["switch"]
          result[:hardware] = get_hardwares(switch)

          return switch.uuid, result
        end

        private

        def get_hardwares(node)
          {
            :firmwares     => get_firmwares(node),
            :guest_devices => get_ports(node),
            :networks      => get_networks(node)
          }
        end

        def get_ports(node)
          node.ports&.map { |port| parse_port(port) }
        end

        def get_networks(node)
          get_parsed_switch_ip_interfaces_by_key(node.ipInterfaces, 'IPv4assignments', node.ipv4Addresses, false) + get_parsed_switch_ip_interfaces_by_key(node.ipInterfaces, 'IPv6assignments', node.ipv6Addresses, true)
        end

        def get_parsed_switch_ip_interfaces_by_key(ip_interfaces, key, address_list, is_ipv6 = false)
          ip_interfaces&.flat_map { |interface| interface[key] }
            .select { |assignment| address_list.include?(assignment['address']) }
            .map { |assignment| parse_network(assignment, is_ipv6) }
        end

        def parse_network(assignment, is_ipv6 = false)
          result = parse(assignment, ParserDictionaryConstants::SWITCH_NETWORK)

          result[:ipaddress]   = assignment['address'] unless is_ipv6
          result[:ipv6address] = assignment['address'] if is_ipv6

          result
        end

        def parse_port(port)
          {
            :device_name      => port["portName"].presence || port["port"],
            :device_type      => "physical_port",
            :peer_mac_address => port["peerMacAddress"].presence
          }
        end

        def get_firmwares(node)
          node.firmware&.map { |firmware| FirmwareParser.parse_firmware(firmware) }
        end
      end
    end
  end
end
