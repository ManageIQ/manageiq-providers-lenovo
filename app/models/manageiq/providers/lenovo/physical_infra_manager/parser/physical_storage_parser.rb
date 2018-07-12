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
        :type                 => :type,
        :health_state         => :health_state,
        :physical_disks       => :physical_disks,
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
            :guest_devices => :guest_devices
          }
        }
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

        result[:physical_rack]    = rack if rack
        result[:physical_chassis] = chassis if chassis
        result
      end

      private

      def type(_storage)
        'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalStorage'
      end

      def health_state(storage)
        HEALTH_STATE_MAP[storage.cmmHealthState.nil? ? storage.cmmHealthState : storage.cmmHealthState.downcase]
      end

      def physical_disks(storage)
        return parse_drivers_inside_components(storage.canisters) if storage.canisters.present?
        parse_drivers_inside_components(storage.enclosures) if storage.enclosures.present?
      end

      def parse_drivers_inside_components(components)
        drivers = []

        components.each do |component|
          component['drives'].each do |driver|
            drivers << parse_driver(driver)
          end
        end

        drivers
      end

      def parse_driver(driver)
        {
          :model         => driver['model'],
          :vendor        => driver['vendorName'],
          :status        => driver['status'],
          :location      => driver['location'],
          :serial_number => driver['serialNumber'],
          :health_state  => driver['health'],
          :type          => driver['type'],
          :disk_size     => driver['size']
        }
      end

      def guest_devices(storage)
        [{
          :device_type => 'management',
          :network     => {
            :ipaddress => storage.mgmtProcIPaddress
          }
        }]
      end
    end
  end
end
