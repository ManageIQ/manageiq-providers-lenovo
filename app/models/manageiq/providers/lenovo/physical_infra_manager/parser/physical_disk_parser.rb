module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalDiskParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [XClarityClient::Storage] to a [Hash] with symbols of PhysicalDisk fields
      PHYSICAL_DISK = {
        :model           => 'model',
        :vendor          => 'vendorName',
        :status          => 'status',
        :location        => 'location',
        :serial_number   => 'serialNumber',
        :health_state    => 'health',
        :controller_type => 'type',
        :disk_size       => :disk_size
      }.freeze

      #
      # Parse disk into a hash
      #
      # @param [Hash] disk_hash - hash containing physical disk raw data
      # @param [Hash] canister - parsed canister data
      #
      # @return [Hash] containing the physical disk information
      #
      def parse_physical_disk(disk, canister: nil)
        result = parse(disk, PHYSICAL_DISK)
        result[:canister] = canister if canister

        result
      end

      def disk_size(disk)
        disk['size']
      end
    end
  end
end
