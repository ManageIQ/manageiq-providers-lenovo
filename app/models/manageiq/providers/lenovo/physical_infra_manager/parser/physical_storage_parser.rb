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
        :canisters            => :canisters,
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
      def parse_physical_storage(storage, rack, chassis)
        result = parse(storage, PHYSICAL_STORAGE)

        result[:physical_rack]    = rack if rack
        result[:physical_chassis] = chassis if chassis
        result[:total_space]      = get_total_space(result)

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
          :model           => driver['model'],
          :vendor          => driver['vendorName'],
          :status          => driver['status'],
          :location        => driver['location'],
          :serial_number   => driver['serialNumber'],
          :health_state    => driver['health'],
          :controller_type => driver['type'],
          :disk_size       => driver['size']
        }
      end

      #
      # @param storage [Hash] Hash with parsed storage data (including physical_disks in it)
      #
      def get_total_space(storage)
        total_space = 0
        disks = storage[:physical_disks]

        disks&.each do |disk|
          total_space += disk[:disk_size].to_i
        end

        total_space.zero? ? nil : total_space.gigabytes # returns the size in bytes
      end

      def canisters(storage)
        return parse_canisters_inside_components(storage.enclosures) if storage.enclosures.present?
        parse_canisters_inside_storage(storage) if storage.enclosures.blank?
      end

      def parse_canisters_inside_storage(storage)
        canisters = []
        storage.canisters.each do |canister|
          canisters << parse_canister(canister)
        end
        canisters
      end

      def parse_canisters_inside_components(components)
        canisters = []
        components.each do |component|
          component['canisters'].each do |canister|
            canisters << parse_canister(canister)
          end
        end
        canisters
      end

      def parse_canister(canister)
        {
          :serial_number                => canister['serialNumber'],
          :name                         => canister['cmmDisplayName'],
          :position                     => canister['position'],
          :status                       => canister['status'],
          :health_state                 => canister['health'],
          :disk_bus_type                => canister['diskBusType'],
          :phy_isolation                => canister['phyIsolation'],
          :controller_redundancy_status => canister['controllerRedundancyStatus'],
          :disks                        => canister['disks'],
          :disk_channel                 => canister['diskChannel'],
          :system_cache_memory          => canister['systemCacheMemory'],
          :power_state                  => canister['powerState'],
          :host_ports                   => canister['hostPorts'],
          :hardware_version             => canister['hardwareVersion'],
          :computer_system              => {
            :hardware => {
              :guest_devices => canister_guest_devices(canister)
            }
          }
        }
      end

      def canister_guest_devices(canister)
        management_device = parent::ManagementDeviceParser.parse_canister_management_device(canister)
        management_device ? [management_device] : []
      end
    end
  end
end
