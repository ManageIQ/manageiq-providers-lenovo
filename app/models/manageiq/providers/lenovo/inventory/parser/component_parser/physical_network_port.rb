module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::PhysicalNetworkPort < Inventory::Parser::ComponentParser
    PHYSICAL_NETWORK_PORT = {
      :port_name   => :port_name,
      :port_type   => :port_type,
      :port_status => 'status'
    }.freeze

    # Mapping between fields inside [Hash] Physical Switch Port to a [Hash] with symbols as keys
    PHYSICAL_SWITCH_PORT = {
      :peer_mac_address => 'peerMacAddress',
      :vlan_key         => 'PVID',
      :port_name        => :port_name,
      :port_type        => :port_type,
      :vlan_enabled     => :vlan_enabled
    }.freeze

    def build_server_network_device_ports(ports, parent)
      parse_network_device_ports(ports).each do |parsed_port|
        add_parent(parsed_port, parent)
        @persister.physical_server_network_ports.build(parsed_port)
      end
    end

    def build_physical_switch_ports(switch_xclarity, parent)
      parse_physical_switch_ports(switch_xclarity) do |parsed_port|
        add_parent(parsed_port, parent)
        @persister.physical_switch_network_ports.build(parsed_port)
      end
    end

    def build_canister_ports(ports, parent)
      ports&.each do |port|
        parsed_port = parse(port, PHYSICAL_NETWORK_PORT)
        add_parent(parsed_port, parent)

        @persister.physical_storage_network_ports.build(parsed_port)
      end
    end

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
      physical_switch.ports&.each do |port|
        yield parse_switch_port(port, physical_switch)
      end
    end

    #
    # Binds the connected ports
    #
    def bind_network_ports!
      ports = @persister.physical_server_network_ports.data +
              @persister.physical_switch_network_ports.data

      ports.each do |origin_port|
        connected_port = ports.find { |destination_port| connected_port?(origin_port, destination_port) }
        origin_port.data[:connected_port_uid] = connected_port.data[:uid_ems] if connected_port
      end
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

    def parse_switch_port(port, physical_switch)
      result = parse(port, PHYSICAL_SWITCH_PORT)
      result[:uid_ems] = mount_uuid_switch_port(port, physical_switch)
      result
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

    def format_mac_address(mac_address)
      mac_address.scan(/\w{2}/).join(":")
    end

    def mount_uuid_server_port(device, port_number = nil)
      # Most devices have a UUID, but if they do not, use the unformatted MAC address
      # of the current port. In the unlikely case that there is no UUID and no MAC address,
      # use the PCI bus number concatenated with the PCI device number and the port
      # number; we realize that this combination is not unique, but it is better than nil.
      if device["uuid"]
        device["uuid"] + port_number.to_s
      else
        physical_ports = device.dig("portInfo", "physicalPorts")
        matching_port = physical_ports&.select { |physical_port| physical_port["physicalPortIndex"] == port_number }
        mac_address = matching_port&.dig(0, "logicalPorts", 0, "addresses")

        if mac_address
          mac_address
        else
          "#{device['pciBusNumber']}#{device['pciDeviceNumber']}" + port_number.to_s
        end
      end
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
      return origin_port.data[:mac_address] == destination_port.data[:peer_mac_address] if origin_port[:mac_address].present?

      return origin_port.data[:peer_mac_address] == destination_port.data[:mac_address] if origin_port[:peer_mac_address].present?

      false
    end
  end
end
