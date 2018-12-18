module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::ConfigPattern < Inventory::Parser::ComponentParser
    # Mapping between fields inside [XClarityClient::ConfigPattern] to a [Hash] with symbols of ConfigPattern fields
    CONFIG_PATTERNS = {
      :manager_ref  => 'id',
      :name         => 'name',
      :description  => 'description',
      :user_defined => 'userDefined',
      :in_use       => 'inUse',
      :type         => :type
    }.freeze

    def build(config_pattern)
      properties = parse_config_pattern(config_pattern)

      @persister.customization_scripts.build(properties)
    end

    #
    # Parses the config pattern object into a Hash
    #
    # @param [XClarityClient::ConfigPattern] config_pattern - object containing config
    #   pattern data
    #
    # @return [Hash] containing the config pattern informations
    #
    def parse_config_pattern(config_pattern)
      parse(config_pattern, CONFIG_PATTERNS)
    end

    def type(_config_pattern)
      'ManageIQ::Providers::Lenovo::PhysicalInfraManager::ConfigPattern'
    end
  end
end
