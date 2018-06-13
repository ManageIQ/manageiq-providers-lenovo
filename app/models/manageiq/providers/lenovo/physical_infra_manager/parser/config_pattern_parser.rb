module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::ConfigPatternParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [XClarityClient::ConfigPattern] to a [Hash] with symbols of ConfigPattern fields
      CONFIG_PATTERNS = {
        :manager_ref  => 'id',
        :name         => 'name',
        :description  => 'description',
        :user_defined => 'userDefined',
        :in_use       => 'inUse'
      }.freeze

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
    end
  end
end
