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

      CANISTER_MANAGEMENT_DEVICE = {
        :address     => 'macAddress',
        :device_name => 'name',
        :device_type => :device_type,
        :network     => {
          :ipaddress   => 'ipAddress',
          :subnet_mask => 'networkMask'
        },
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

      def parse_canister_management_device(canister)
        if canister['networkPorts'].present?
          canister_management_device = parse(canister['networkPorts'], CANISTER_MANAGEMENT_DEVICE)
          canister_management_device[:physical_network_ports] = canister_physical_network_ports(canister)

          canister_management_device
        end
      end

      private

      def device_type(_node)
        'management'
      end

      def ipv6address(node)
        node.ipv6Addresses&.join(', ')
      end

      def canister_physical_network_ports(canister)
        parent::PhysicalNetworkPortsParser.parse_physical_network_ports(canister['ports'])
      end
    end
  end
end
