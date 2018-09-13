module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::ManagementDeviceParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [Hash] of a Management Device to a [Hash] with symbols
      MANAGEMENT_DEVICE = {
        :address     => 'macAddress',
        :device_type => :device_type,
        :network     => {
          :ipaddress   => 'mgmtProcIPaddress',
          :ipv6address => :ipv6address
        }
      }.freeze

      #
      # Parse a node object to get Its management device
      #
      # @param [Hash] node - Node that contains a Management Device attached to It
      #
      # @return [Hash] containing the management device information
      #
      def parse_management_device(node)
        parse(node, MANAGEMENT_DEVICE)
      end

      private

      def device_type(_node)
        'management'
      end

      def ipv6address(node)
        node.ipv6Addresses&.join(', ')
      end
    end
  end
end
