module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalSwitchPortsParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [Hash] Physical Switch Port to a [Hash] with symbols as keys
      PHYSICAL_SWITCH_PORT = {
        :peer_mac_address => 'peerMacAddress',
        :vlan_key         => 'PVID',
        :port_name        => :port_name,
        :port_type        => :port_type,
        :vlan_enabled     => :vlan_enabled,
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
        parse(port, PHYSICAL_SWITCH_PORT)
      end

      def port_name(port)
        port['portName'].presence || port['port']
      end

      def port_type(_port)
        'physical_port'
      end

      def vlan_enabled(port)
        port['PVID'].present?
      end
    end
  end
end
