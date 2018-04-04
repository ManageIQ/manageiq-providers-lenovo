require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class PhysicalRackParser < ComponentParser
      class << self
        #
        # Parse a rack object to a hash with its data
        #
        # @param cab [XClarity::PhysicalRack] a rack object
        # @param physical_servers [Hash] a already parsed physical_servers that belong to cab
        #
        # @return [Integer, Hash] PhysicalRack UUID and a parsed hash from PhysicalRack and every components inside it
        #
        def parse_physical_rack(cab)
          result = parse(cab, ParserDictionaryConstants::PHYSICAL_RACK)

          return cab.UUID, result
        end
      end
    end
  end
end
