module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::StorageDeviceParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # @param [XClarityClient::Node] component - component that has storage devices
      #
      def parse_storage_device(component)
        devices = distinct_storage_devices(select_storage_devices(component))

        devices.map do |device|
          parse_device(device)
        end
      end

      private

      #
      # Mount the storage device from a hash object
      #
      # @param [Hash] device - a hash containing the storage device informations
      #
      def parse_device(device)
        result = parse(device, parent::ParserDictionaryConstants::GUEST_DEVICE)

        result[:uid_ems]     = mount_uuid(device)
        result[:device_name] = device['productName'] ? device['productName'] : device['name']
        result[:device_type] = 'storage'
        result[:firmwares]   = parse_device_firmware(device)
        result[:location]    = device['slotNumber'] ? "Bay #{device['slotNumber']}" : nil

        result
      end

      #
      # Selects all storage devices.
      #   The storage devices could be in `pci_devices` or `addin_cards` prop
      #
      def select_storage_devices(component)
        pci_devices = component.try(:pciDevices).try(:select) { |device| storage_device?(device) }
        addin_cards = component.try(:addinCards).try(:select) { |device| storage_device?(device) }

        devices = []
        devices.concat(pci_devices) if pci_devices.present?
        devices.concat(addin_cards) if addin_cards.present?
        devices
      end

      def distinct_storage_devices(devices)
        devices.uniq { |device| mount_uuid(device) }
      end

      def storage_device?(device)
        device_name = (device['productName'] ? device['productName'] : device['name']).try(:downcase)
        device['class'] == 'Mass storage controller' || device_name =~ /serveraid/ || device_name =~ /sd media raid/
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

      def mount_uuid(device)
        device['uuid'] || "#{device['pciBusNumber']}#{device['pciDeviceNumber']}"
      end
    end
  end
end
