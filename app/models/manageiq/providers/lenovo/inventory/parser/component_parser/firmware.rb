module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::Firmware < Inventory::Parser::ComponentParser
    # Mapping between fields of [Hash] Firmware to a [Hash] with symbols of Firmware fields
    FIRMWARE = {
      :build        => 'build',
      :version      => 'version',
      :release_date => 'date',
      :name         => :name
    }.freeze

    FORMAT_BY_TYPE_ROLE = %w(UEFI IMM2 XCC).freeze
    FORMAT_BY_NAME = %w(DRVWN LXPM DRVLN).freeze
    FORMAT_BY_DISTINCT_NAME = {
      'DSA' => 'Diagnostic',
    }.freeze

    RULES = {
      :format_by_name          => FORMAT_BY_NAME,
      :format_by_type_role     => FORMAT_BY_TYPE_ROLE,
      :format_by_distinct_name => FORMAT_BY_DISTINCT_NAME
    }.freeze

    PARSER_FIRMWARE_TYPE = {
      'UEFI-Backup' => 'UEFI',
      'IMM2-Backup' => 'IMM2',
      'XCC-Backup'  => 'XCC'
    }.freeze

    def build(firmware, inventory_collection_name, parent, component = nil)
      hash = parse_firmware(firmware, component)
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
    def parse_firmware(firmware, component = nil)
      @component = component
      parse(firmware, FIRMWARE)
    end

    def name(firmware)
      firmware_name = @component&.[]('name') == 'N/A' ? firmware['name'] : @component&.[]('name')
      return firmware_name if firmware_name.present?
      send(method_name(firmware), firmware)
    end

    private

    def method_name(firmware)
      type = PARSER_FIRMWARE_TYPE[firmware['type']] || firmware['type']
      method, _value = RULES.detect { |_method, value| value.include?(type) }
      method.nil? ? "default_name" : method
    end

    def format_by_name(firmware)
      firmware['name'] || default_name(firmware)
    end

    def format_by_type_role(firmware)
      type = PARSER_FIRMWARE_TYPE[firmware['type']] || firmware['type']
      firmware['role'].present? ? "#{type} (#{firmware['role']})" : default_name(firmware)
    end

    def format_by_distinct_name(firmware)
      FORMAT_BY_DISTINCT_NAME[firmware['type']]
    end

    def default_name(firmware)
      "#{firmware['role']} #{firmware['name']} - #{firmware['status'].titleize}".strip
    end
  end
end
