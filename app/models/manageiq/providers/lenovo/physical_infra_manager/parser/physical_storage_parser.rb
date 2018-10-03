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
        parse_drivers_inside_multi_enclosures(storage) if storage.enclosures.present?
      end

      def parse_drivers_inside_multi_enclosures(storage)
        drivers = []
        storage.enclosures.each do |enclosure|
          drivers << parse_drivers_inside_single_component(enclosure, :storage => storage)
        end

        drivers.flatten
      end

      def parse_drivers_inside_single_component(parent, storage: nil)
        drivers = []
        driver_index = 0

        parent['drives']&.each do |driver|
          drivers << if storage.present?
                       parse_storage_driver(storage, driver, driver_index.to_s)
                     else
                       parse_canister_driver(parent, driver, driver_index.to_s)
                     end
          driver_index += 1
        end

        drivers
      end

      def parse_storage_driver(storage, driver, driver_index)
        result = parent::PhysicalDiskParser.parse_physical_disk(driver)
        result[:ems_ref] = storage.uuid + '_' + driver_index

        result
      end

      def parse_canister_driver(canister, driver, driver_index)
        result = parent::PhysicalDiskParser.parse_physical_disk(driver, :canister => canister)
        result[:ems_ref] = canister['uuid'] + '_' + driver_index

        result
      end

      #
      # @param storage [Hash] Hash with parsed storage data (including physical_disks in it)
      #
      def get_total_space(storage)
        total_space = 0
        disks = storage[:physical_disks]
        disks&.each { |disk| total_space += disk[:disk_size].to_i }

        total_space.zero? ? nil : total_space.gigabytes # returns the size in bytes
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
          :ems_ref                      => canister['uuid'],
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
          :physical_disks               => parse_drivers_inside_single_component(canister),
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
