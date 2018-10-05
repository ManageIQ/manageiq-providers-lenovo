module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::NetworkDevice < Inventory::Parser::ComponentParser::GuestDevice
    # Network device is associated only to physical_server
    # @param node [XClarity::Node]
    # @param parent [Hash] {:belongs_to => [Symbol], :object => [InventoryObject]}
    def build(node, parent)
      parse_network_devices(node) do |parsed_device, device, all_devices|
        add_parent(parsed_device, parent)

        network_device = @persister.physical_server_network_devices.build(parsed_device)

        build_firmwares(device, network_device)
        build_physical_network_ports(network_device, device, all_devices)
      end
    end

    #
    # @param component - component that has network devices to be parsed
    #
    def parse_network_devices(component)
      all_devices = select_network_devices(component)

      distinct_devices = distinct_network_devices(all_devices)

      distinct_devices.each do |device|
        parsed_device = parse_guest_device(device)

        yield parsed_device, device, all_devices
      end
    end

    private

    def build_physical_network_ports(device_inventory_object, device, all_devices)
      ports = all_devices.select { |device_with_port| uid_ems(device) == uid_ems(device_with_port) }


      components(:physical_network_ports).build_server_network_device_ports(ports,
                                                                            :belongs_to => :guest_device,
                                                                            :object     => device_inventory_object)
    end

    #
    # Selects all network devices.
    #   The network devices could be in `pciDevices` or `addinCards` prop
    #
    # @return a list with all network devices of the component
    #   (it could have duplicated entries if the entry is in both properties)
    #
    def select_network_devices(component)
      pci_devices = component.try(:pciDevices).try(:select) {|device| network_device?(device)}
      addin_cards = component.try(:addinCards).try(:select) {|device| network_device?(device)}

      devices = []
      devices.concat(pci_devices) if pci_devices.present?
      devices.concat(addin_cards) if addin_cards.present?
      devices
    end

    #
    # Distincts the network devices by pciSubID property (remove duplicated entries)
    #
    def distinct_network_devices(devices)
      devices.uniq {|device| uid_ems(device)}
    end

    #
    # Verifies if a device is a network device by it name or it class
    #
    def network_device?(device)
      device_name = (device['productName'] ? device['productName'] : device['name']).try(:downcase)
      device['class'] == 'Network controller' || device_name =~ /nic/ || device_name =~ /ethernet/
    end

    def device_type(_device)
      'ethernet'
    end
  end
end
