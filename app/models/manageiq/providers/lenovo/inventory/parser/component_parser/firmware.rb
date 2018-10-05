module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::Firmware < Inventory::Parser::ComponentParser
    # Mapping between fields of [Hash] Firmware to a [Hash] with symbols of Firmware fields
    FIRMWARE = {
      :build        => 'build',
      :version      => 'version',
      :release_date => 'date',
      :name         => :name
    }.freeze

    def build(firmware, inventory_collection_name, parent)
      hash = parse_firmware(firmware)
      add_parent(hash, parent)

      @persister.send(inventory_collection_name).build(hash)
    end

    #
    # Parses a firmware into a Hash
    #
    # @param [Hash] firmware - object containing details for the firmware
    #
    # @return [Hash] the firmware as required by the application
    #
    def parse_firmware(firmware)
      parse(firmware, FIRMWARE)
    end

    def name(firmware)
      "#{firmware['role']} #{firmware['name']}-#{firmware['status']}".strip
    end
  end
end
