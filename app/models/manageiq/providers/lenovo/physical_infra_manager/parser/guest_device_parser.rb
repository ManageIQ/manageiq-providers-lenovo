module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::GuestDeviceParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [Hash] Guest Device to a [Hash] with symbols as keys
      GUEST_DEVICE = {
        :manufacturer           => 'manufacturer',
        :field_replaceable_unit => 'FRU',
        :controller_type        => 'class',
        :uid_ems                => :uid_ems,
        :device_name            => :device_name,
        :device_type            => :device_type,
        :firmwares              => :firmwares,
        :location               => :location
      }.freeze

      #
      # Mounts a Guest Device
      #
      # @param [Hash] guest_device - a raw device that needs to be parsed
      #
      def parse_guest_device(guest_device)
        parse(guest_device, GUEST_DEVICE)
      end

      private

      def uid_ems(device)
        device['uuid'] || "#{device['pciBusNumber']}#{device['pciDeviceNumber']}"
      end

      def device_name(device)
        device['productName'] ? device['productName'] : device['name']
      end

      def device_type(_device)
        'guest_device'
      end

      def firmwares(device)
        device_fw = []

        firmware = device['firmware']
        unless firmware.nil?
          device_fw = firmware.map do |fw|
            parent::FirmwareParser.parse_firmware(fw)
          end
        end

        device_fw
      end

      def location(device)
        device['slotNumber'] ? "Bay #{device['slotNumber']}" : nil
      end
    end
  end
end
