module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::FirmwareParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields of [Hash] Firmware to a [Hash] with symbols of Firmware fields
      FIRMWARE = {
        :build        => 'build',
        :version      => 'version',
        :release_date => 'date'
      }.freeze

      #
      # Parses a firmware into a Hash
      #
      # @param [Hash] firmware - object containing details for the firmware
      #
      # @return [Hash] the firmware as required by the application
      #
      def parse_firmware(firmware)
        result = parse(firmware, FIRMWARE)

        result[:name] = "#{firmware['role']} #{firmware['name']}-#{firmware['status']}".strip

        result
      end
    end
  end
end
