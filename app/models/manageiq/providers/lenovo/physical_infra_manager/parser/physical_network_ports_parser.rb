module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalNetworkPortsParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [Hash] Physical Switch Port to a [Hash] with symbols as keys
      PHYSICAL_SWITCH_PORT = {
        :peer_mac_address => 'peerMacAddress',
        :vlan_key         => 'PVID'
      }.freeze

      #
      # Mounts the ports from Network Device
      #
      def parse_network_device_ports(ports)
        parsed_ports = []

        ports.each do |port|
          parsed_port = parse_physical_server_ports(port)
          parsed_ports.concat(parsed_port) if parsed_port.present?
        end

        parsed_ports.uniq { |port| port[:port_name] }
      end

      #
      # Mounts the Physical Switches ports
      #
      # @param [XClarityClient::Switch] physical_switch - The switch to have
      #   it ports parsed
      #
      def parse_physical_switch_ports(physical_switch)
        physical_switch.ports&.map { |port| parse_switch_port(port, physical_switch) }
      end

      #
      # Binds the connected ports
      #
      # @param [Array<Hash>] ports - parsed ports to be bind
      #
      def bind_network_ports!(ports)
        ports.each do |origin_port|
          connected_port = ports.find { |destination_port| connected_port?(origin_port, destination_port) }
          origin_port[:connected_port_uid] = connected_port[:uid_ems] if connected_port
        end
      end

      #
      # Selects all the physical network port from physical servers list.
      #
      # @param [Array<Hash>] physical_servers - list of physical servers that must
      #   have its ports selecteds.
      #
      # @return [Array<Hash>] the list of physical network ports
      #
      def extract_physical_servers_ports(physical_servers)
        ports = []

        physical_servers.each do |server|
          network_devices = server[:computer_system][:hardware][:guest_devices]

          network_devices.each do |device|
            ports.concat(device[:physical_network_ports]) if device[:physical_network_ports].present?
          end
        end

        ports
      end

      #
      # Selects all the physical network port from physical switches list.
      #
      # @param [Array<Hash>] physical_switches - list of physical switches that must
      #   have its ports selecteds.
      #
      # @return [Array<Hash>] the list of physical network ports
      #
      def extract_physical_switches_ports(physical_switches)
        ports = []

        physical_switches.each do |switch|
          ports.concat(switch[:physical_network_ports]) if switch[:physical_network_ports].present?
        end

        ports
      end

      private

      def parse_physical_server_ports(port)
        port_info = port["portInfo"]
        physical_ports = port_info&.dig('physicalPorts')
        physical_ports&.map do |physical_port|
          parsed_physical_port = parse_physical_port(physical_port)
          logical_ports = physical_port["logicalPorts"]
          parsed_logical_port = parse_logical_port(logical_ports[0])
          parsed_logical_port[:uid_ems] = mount_uuid_server_port(port, physical_port['physicalPortIndex'])
          parsed_logical_port.merge!(parsed_physical_port)

          parsed_logical_port
        end
      end

      def parse_switch_port(port, physical_switch)
        result = parse(port, PHYSICAL_SWITCH_PORT)
        result.merge(
          :port_name    => port["portName"].presence || port["port"],
          :port_type    => "physical_port",
          :vlan_enabled => port["PVID"].present?,
          :uid_ems      => mount_uuid_switch_port(port, physical_switch)
        )
      end

      def parse_physical_port(port)
        {
          :port_type  => port["portType"],
          :port_name  => "Physical Port #{port['physicalPortIndex']}",
          :port_index => port['physicalPortIndex'],
        }
      end

      def parse_logical_port(port)
        {
          :mac_address => format_mac_address(port["addresses"])
        }
      end

      def format_mac_address(mac_address)
        mac_address.scan(/\w{2}/).join(":")
      end

      def mount_uuid_server_port(device, port_number = nil)
        (device["uuid"] || "#{device['pciBusNumber']}#{device['pciDeviceNumber']}") + port_number.to_s
      end

      def mount_uuid_switch_port(port, physical_switch)
        physical_switch.uuid + port['port'].to_s
      end

      #
      # Verifies if two ports are connected
      #
      # @return [Boolean] true if they are connected
      #
      def connected_port?(origin_port, destination_port)
        return origin_port[:mac_address] == destination_port[:peer_mac_address] if origin_port[:mac_address].present?

        return origin_port[:peer_mac_address] == destination_port[:mac_address] if origin_port[:peer_mac_address].present?

        false
      end
    end
  end
end
