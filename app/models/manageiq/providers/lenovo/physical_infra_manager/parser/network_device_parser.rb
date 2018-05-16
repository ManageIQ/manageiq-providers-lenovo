module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::NetworkDeviceParser < PhysicalInfraManager::Parser::GuestDeviceParser
    class << self
      #
      # @param component - component that has network devices to be parseds
      #
      def parse_network_devices(component)
        all_devices = select_network_devices(component)

        distinct_devices = distinct_network_devices(all_devices)

        distinct_devices.map do |device|
          parsed_device = parse_guest_device(device)
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
        devices.uniq { |device| uid_ems(device) }
      end

      #
      # Verifies if a device is a network device by it name or it class
      #
      def network_device?(device)
        device_name = (device['productName'] ? device['productName'] : device['name']).try(:downcase)
        device['class'] == 'Network controller' || device_name =~ /nic/ || device_name =~ /ethernet/
      end

      def parse_physical_network_ports(device, all_devices)
        ports = all_devices.select { |device_with_port| uid_ems(device) == uid_ems(device_with_port) }

        parent::PhysicalNetworkPortsParser.parse_network_device_ports(ports)
      end

      def device_type(_device)
        'ethernet'
      end
    end
  end
end
