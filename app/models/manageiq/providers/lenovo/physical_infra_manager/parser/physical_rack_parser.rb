module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalRackParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside [XClarity:PhysicalRack] to a [Hash] with symbols of PhysicalRack fields
      PHYSICAL_RACK = {
        :name    => 'cabinetName',
        :uid_ems => 'UUID',
        :ems_ref => 'UUID'
      }.freeze

      #
      # Parse a rack object to a hash with its data
      #
      # @param cab [XClarity::PhysicalRack] a rack object
      #
      # @return [Integer, Hash] PhysicalRack UUID and a parsed hash from PhysicalRack and every components inside it
      #
      def parse_physical_rack(cab)
        parse(cab, PHYSICAL_RACK)
      end
    end
  end
end
