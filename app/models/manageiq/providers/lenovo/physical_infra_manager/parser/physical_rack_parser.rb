module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalRackParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # Parse a rack object to a hash with its data
      #
      # @param cab [XClarity::PhysicalRack] a rack object
      #
      # @return [Integer, Hash] PhysicalRack UUID and a parsed hash from PhysicalRack and every components inside it
      #
      def parse_physical_rack(cab)
        parse(cab, parent::ParserDictionaryConstants::PHYSICAL_RACK)
      end
    end
  end
end
