module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::StorageDeviceParser < PhysicalInfraManager::Parser::GuestDeviceParser
    class << self
      #
      # @param [XClarityClient::Node] component - component that has storage devices
      #
      def parse_storage_device(component)
        devices = distinct_storage_devices(select_storage_devices(component))

        devices.map do |device|
          parse_guest_device(device)
        end
      end

      private

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
        devices.uniq { |device| uid_ems(device) }
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
end
