module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::ManagementDeviceParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [Hash] of a Management Device to a [Hash] with symbols
      MANAGEMENT_DEVICE = {
        :address => 'macAddress',
        :network => {
          :ipaddress => 'mgmtProcIPaddress'
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
        result = parse(node, MANAGEMENT_DEVICE)

        result[:device_type] = 'management'
        result[:network][:ipv6address] = node.ipv6Addresses&.join(', ')

        result
      end
    end
  end
end
