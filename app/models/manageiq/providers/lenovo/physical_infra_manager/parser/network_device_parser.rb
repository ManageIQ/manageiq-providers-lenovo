module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::NetworkDeviceParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # @param component - component that has network devices to be parseds
      #
      def parse_network_devices(component)
        all_devices = select_network_devices(component)

        distinct_devices = distinct_network_devices(all_devices)

        distinct_devices.map do |device|
          parsed_device = parse_device(device)
          parsed_device[:physical_network_ports] = parse_physical_network_ports(device, all_devices)
          parsed_device
        end
      end

      private

      #
      # Selects all network devices.
      #   The network devices could be in `pciDevices` or `addinCards` prop
      #
      # @return a list with all network devices of the component
      #   (it could have duplicated entries if the entry is in both properties)
      #
      def select_network_devices(component)
        pci_devices = component.try(:pciDevices).try(:select) { |device| network_device?(device) }
        addin_cards = component.try(:addinCards).try(:select) { |device| network_device?(device) }

        devices = []
        devices.concat(pci_devices) if pci_devices.present?
        devices.concat(addin_cards) if addin_cards.present?
        devices
      end

      #
      # Distincts the network devices by pciSubID property (remove duplicated entries)
      #
      def distinct_network_devices(devices)
        devices.uniq { |device| mount_uuid(device) }
      end

      #
      # Verifies if a device is a network device by it name or it class
      #
      def network_device?(device)
        device_name = (device['productName'] ? device['productName'] : device['name']).try(:downcase)
        device['class'] == 'Network controller' || device_name =~ /nic/ || device_name =~ /ethernet/
      end

      def parse_device(device)
        result = parse(device, parent::ParserDictionaryConstants::GUEST_DEVICE)

        result[:uid_ems]     = mount_uuid(device)
        result[:device_name] = device['productName'] ? device['productName'] : device['name']
        result[:device_type] = 'ethernet'
        result[:firmwares]   = parse_device_firmware(device)
        result[:location]    = device['slotNumber'] ? "Bay #{device['slotNumber']}" : nil

        result
      end

      def parse_device_firmware(device)
        device_fw = []

        firmware = device['firmware']
        unless firmware.nil?
          device_fw = firmware.map do |fw|
            parent::FirmwareParser.parse_firmware(fw)
          end
        end

        device_fw
      end

      def parse_physical_network_ports(device, all_devices)
        ports = all_devices.select { |device_with_port| mount_uuid(device) == mount_uuid(device_with_port) }

        parent::PhysicalNetworkPortsParser.parse_network_device_ports(ports)
      end

      #
      # Mounts the uuid for the devices
      #   For those devices that hasn't an uuid this method uses others properties to mount one
      #
      # @param device       - device that needs an uuid
      # @param child_device - if the device is a child device, it uuid will be the same
      # @param port_number  - number of the port of the child device that will be concat to the uuid
      #
      def mount_uuid(device)
        device['uuid'] || "#{device['pciBusNumber']}#{device['pciDeviceNumber']}"
      end
    end
  end
end
