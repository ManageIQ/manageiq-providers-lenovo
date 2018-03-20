module ManageIQ::Providers::Lenovo
  #
  # Class that provides methods to parse LXCA data to ManageIQ data.
  # The parse methods inside this class works with versions:
  # 1.3
  # 1.4
  # 2.0
  # If for a specific version needs some different strategy, please
  # create a subclass overriding the old with the new parse strategy, and bind this subclass
  # on +VERSION_PARSERS+ constant.
  #
  class Parser
    require_relative 'parsers'

    # Suported API versions.
    # To support a new version with some subclass, update this constant like this:
    # '<version>' => ManageIQ::Providers::Lenovo::<Class>
    VERSION_PARSERS = {
      'default' => ManageIQ::Providers::Lenovo::Parser,
    }.freeze

    # returns the parser of api version request
    # see the +VERSION_PARSERS+ to know what versions are supporteds
    def self.get_instance(version)
      version_parser = version.match(/^(?:(\d+)\.?(\d+))/).to_s # getting just major and minor version
      parser = VERSION_PARSERS[version_parser] # getting the class that supports the version
      parser ||= VERSION_PARSERS['default']
      parser.new
    end

    def parse_switch(node)
      Parsers::SwitchParser.parse_switch(node)
    end

    def parse_physical_server(node)
      Parsers::PhysicalServerParser.parse_physical_server(node)
    end

    def parse_config_pattern(config_pattern)
      Parsers::ConfigPatternParser.parse_config_pattern(config_pattern)
    end
  end
end
