module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalStorageParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [XClarityClient::Storage] to a [Hash] with symbols of PhysicalStorage fields
      PHYSICAL_STORAGE = {
        :name                 => 'name',
        :uid_ems              => 'uuid',
        :ems_ref              => 'uuid',
        :access_state         => 'accessState',
        :overall_health_state => 'overallHealthState',
        :drive_bays           => 'driveBays',
        :enclosures           => 'enclosureCount',
        :canister_slots       => 'canisterSlots',
        :asset_detail         => {
          :product_name     => 'productName',
          :machine_type     => 'machineType',
          :model            => 'model',
          :serial_number    => 'serialNumber',
          :contact          => 'contact',
          :description      => 'description',
          :location         => 'location.location',
          :room             => 'location.room',
          :rack_name        => 'location.rack',
          :lowest_rack_unit => 'location.lowestRackUnit',
        },
        :computer_system      => {
          :hardware => {
            :guest_devices => '',
          },
        },
      }.freeze

      PHYSICAL_STORAGE_NETWORK = {
        :ipaddress => 'mgmtProcIPaddress',
      }.freeze

      #
      # Parse a storage into a hash
      #
      # @param [Hash] storage_hash - hash containing physical storage raw data
      # @param [Hash] rack - parsed physical rack data
      # @param [Hash] chassis - parsed physical chassis data
      #
      # @return [Hash] containing the physical storage information
      #
      def parse_physical_storage(storage_hash, rack, chassis)
        storage = XClarityClient::Storage.new(storage_hash)
        result = parse(storage, PHYSICAL_STORAGE)

        result[:physical_rack]              = rack if rack
        result[:physical_chassis]           = chassis if chassis
        result[:type]                       = MIQ_TYPES["physical_storage"]
        result[:health_state]               = HEALTH_STATE_MAP[storage.cmmHealthState.nil? ? storage.cmmHealthState : storage.cmmHealthState.downcase]
        result[:computer_system][:hardware] = get_hardwares(storage)

        result
      end

      private

      def get_hardwares(storage)
        parsed_storage_network = parse(storage, PHYSICAL_STORAGE_NETWORK)

        {
          :guest_devices => [{
            :device_type => "management",
            :network     => parsed_storage_network
          }]
        }
      end
    end
  end
end
