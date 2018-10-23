module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::ManagementDevice < Inventory::Parser::ComponentParser
    # Mapping between fields inside a [Hash] of a Management Device to a [Hash] with symbols
    MANAGEMENT_DEVICE_NODE = {
      :address     => 'macAddress',
      :device_type => :device_type,
      :network     => {
        :ipaddress   => 'mgmtProcIPaddress',
        :ipv6address => :ipv6address
      },
    }.freeze

    MANAGEMENT_DEVICE_CHASSIS = {
      :device_type => :device_type,
      :network     => {
        :ipaddress => 'mgmtProcIPaddress'
      }
    }.freeze

    MANAGEMENT_DEVICE_CANISTER = {
      :address     => 'macAddress',
      :device_name => 'name',
      :device_type => :device_type,
      :network     => {
        :ipaddress   => 'ipAddress',
        :subnet_mask => 'networkMask'
      },
    }.freeze

    def build(component, inventory_collection_name, parent)
      parsed_device = parse_management_device(component)
      add_parent(parsed_device, parent)

      device = @persister.send(inventory_collection_name).build(parsed_device)

      build_network(component, device, parent[:object])

      device
    end

    # @param canister_data [Hash]
    # @param [InventoryObject] hardware
    # @param parent [Hash] { :belongs_to => Symbol, :object => InventoryObject }
    def build_for_canister(canister_data, hardware, parent)
      parsed_device = parse(canister_data['networkPorts'], MANAGEMENT_DEVICE_CANISTER)
      add_parent(parsed_device, parent)

      management_device = @persister.physical_storage_management_devices.build(parsed_device)

      build_canister_network(canister_data['networkPorts'], management_device, hardware)

      build_physical_network_port(canister_data['ports'], management_device)
    end

    def build_physical_network_port(ports, management_device)
      components(:physical_network_port).build_canister_ports(ports,
                                                              :belongs_to => :guest_device,
                                                              :object     => management_device)
    end

    private

    #
    # Parse a node object to get Its management device
    #
    # @param [Hash] component - Node/chassis/storage that contains a Management Device attached to It
    #
    # @return [Hash] containing the management device information
    #
    def parse_management_device(component)
      parse(component, fields_by_component_type(component))
    end

    def build_canister_network(values, device, hardware)
      parsed_network = parse(values, MANAGEMENT_DEVICE_CANISTER[:network])
      add_parent(parsed_network, :belongs_to => :guest_device, :object => device)
      add_parent(parsed_network, :belongs_to => :hardware, :object => hardware)

      parsed_network[:ipaddress] = nil unless parsed_network.key?(:ipaddress)
      parsed_network[:ipv6address] = nil unless parsed_network.key?(:ipv6address)

      @persister.physical_storage_networks.build(parsed_network)
    end

    def build_network(component, device, hardware)
      parsed_network = parse(component, fields_by_component_type(component)[:network])
      add_parent(parsed_network,
                 :belongs_to => :guest_device,
                 :object     => device)

      add_parent(parsed_network,
                 :belongs_to => :hardware,
                 :object     => hardware)

      parent_collection_name = device&.inventory_collection&.association
      inventory_collection_name = case parent_collection_name
                                  when :physical_server_management_devices then :physical_server_networks
                                  when :physical_chassis_management_devices then :physical_chassis_networks
                                  when :physical_storage_management_devices then :physical_storage_networks
                                  else raise "Unknown parent inventory collection (#{parent_collection_name})"
                                  end

      parsed_network[:ipaddress] = nil unless parsed_network.key?(:ipaddress)
      parsed_network[:ipv6address] = nil unless parsed_network.key?(:ipv6address)

      @persister.send(inventory_collection_name).build(parsed_network)
    end

    def device_type(_node)
      'management'
    end

    def ipv6address(node)
      node.ipv6Addresses&.join(', ')
    end

    def fields_by_component_type(component)
      case component
      when XClarityClient::Node then MANAGEMENT_DEVICE_NODE
      when XClarityClient::Chassi then MANAGEMENT_DEVICE_CHASSIS
      else {}
      end
    end
  end
end
