require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class ConfigPatternParser < ComponentParser
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
          return config_pattern.id, parse(config_pattern, ParserDictionaryConstants::CONFIG_PATTERNS)
        end
      end
    end
  end
end
