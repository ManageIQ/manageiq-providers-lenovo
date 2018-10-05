module ManageIQ::Providers::Lenovo
  # Storage device is associated to physical_server
  class Inventory::Parser::ComponentParser::StorageDevice < Inventory::Parser::ComponentParser::GuestDevice
    def build(component, parent)
      parse_storage_device(component) do |parsed_device, device|
        add_parent(parsed_device, parent)

        storage_device = @persister.physical_server_storage_adapters.build(parsed_device)

        build_firmwares(device, storage_device)
      end
    end

    #
    # @param [XClarityClient::Node] component - component that has storage devices
    #
    def parse_storage_device(component)
      devices = distinct_storage_devices(select_storage_devices(component))

      devices.map do |device|
        parsed_device = parse_guest_device(device)

        yield parsed_device, device
      end
    end

    private

    #
    # Selects all storage devices.
    #   The storage devices could be in `pci_devices` or `addin_cards` prop
    #
    def select_storage_devices(component)
      pci_devices = component.try(:pciDevices).try(:select) {|device| storage_device?(device)}
      addin_cards = component.try(:addinCards).try(:select) {|device| storage_device?(device)}

      devices = []
      devices.concat(pci_devices) if pci_devices.present?
      devices.concat(addin_cards) if addin_cards.present?
      devices
    end

    def distinct_storage_devices(devices)
      devices.uniq {|device| uid_ems(device)}
    end

    def storage_device?(device)
      device_name = (device["productName"] ? device["productName"] : device["name"]).try(:downcase)
      device["class"] == "Mass storage controller" || device_name =~ /serveraid/ || device_name =~ /sd media raid/
    end

    def device_type(_device)
      'storage'
    end
  end
end
