module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::ConfigPatternParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # Parses the config pattern object into a Hash
      #
      # @param [XClarityClient::ConfigPattern] config_pattern - object containing config
      #   pattern data
      #
      # @return [Hash] containing the config pattern informations
      #
      def parse_config_pattern(config_pattern)
        parse(config_pattern, parent::ParserDictionaryConstants::CONFIG_PATTERNS)
      end
    end
  end
end
