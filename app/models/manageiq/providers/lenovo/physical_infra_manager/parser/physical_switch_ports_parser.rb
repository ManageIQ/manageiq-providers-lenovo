module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalSwitchPortsParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [Hash] Physical Switch Port to a [Hash] with symbols as keys
      PHYSICAL_SWITCH_PORT = {
        :peer_mac_address => 'peerMacAddress',
        :vlan_key         => 'PVID'
      }.freeze

      #
      # Mounts the Physical Switches ports
      #
      # @param [XClarityClient::Switch] physical_switch - The switch to have
      #   it ports parsed
      #
      def parse_physical_switch_ports(physical_switch)
        physical_switch.ports&.map { |port| parse_switch_port(port) }
      end

      private

      def parse_switch_port(port)
        result = parse(port, PHYSICAL_SWITCH_PORT)
        result.merge(
          :port_name    => port['portName'].presence || port['port'],
          :port_type    => 'physical_port',
          :vlan_enabled => port['PVID'].present?
        )
      end
    end
  end
end
