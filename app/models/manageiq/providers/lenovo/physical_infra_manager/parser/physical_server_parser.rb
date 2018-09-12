module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalServerParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [XClarityClient::Node] to a [Hash] with symbols of PhysicalServer fields
      PHYSICAL_SERVER = {
        :name            => 'name',
        :ems_ref         => 'uuid',
        :uid_ems         => 'uuid',
        :hostname        => 'hostname',
        :asset_detail    => {
          :product_name           => 'productName',
          :manufacturer           => 'manufacturer',
          :machine_type           => 'machineType',
          :model                  => 'model',
          :serial_number          => 'serialNumber',
          :part_number            => 'partNumber',
          :field_replaceable_unit => 'FRU',
          :contact                => 'contact',
          :description            => 'description',
          :location               => 'location.location',
          :room                   => 'location.room',
          :rack_name              => 'location.rack',
          :lowest_rack_unit       => 'location.lowestRackUnit'
        },
        :computer_system => {
          :hardware => {
            :guest_devices => '',
            :firmwares     => ''
          }
        }
      }.freeze

      MANAGEMENT_DEVICE = {
        :address => 'macAddress',
        :network => {
          :ipaddress => 'mgmtProcIPaddress'
        }
      }.freeze

      #
      # parse a node object to a hash with physical servers data
      #
      # @param [Hash] node_hash - hash containing physical server raw data
      # @param [Hash] rack - parsed physical rack data
      # @param [Hash] chassis - parsed physical chassis data
      #
      # @return [Hash] containing the physical server information
      #
      def parse_physical_server(node_hash, compliance, rack = nil, chassis = nil)
        node = XClarityClient::Node.new(node_hash)
        result = parse(node, PHYSICAL_SERVER)

        # Keep track of the rack where this server is in, if it is in any rack
        result[:physical_rack]                       = rack if rack
        result[:physical_chassis]                    = chassis if chassis
        result[:ems_compliance_name]                 = compliance[:policy_name]
        result[:ems_compliance_status]               = compliance[:status]
        result[:vendor]                              = "lenovo"
        result[:type]                                = MIQ_TYPES["physical_server"]
        result[:power_state]                         = POWER_STATE_MAP[node.powerStatus]
        result[:health_state]                        = HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
        result[:host]                                = get_host_relationship(node.serialNumber)
        result[:computer_system][:hardware]          = get_hardwares(node)

        result[:asset_detail].merge!(get_location_led_info(node.leds) || {})

        result
      end

      private

      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      def get_host_relationship(serial_number)
        Host.find_by(:service_tag => serial_number) ||
          Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
      end

      def get_hardwares(node)
        {
          :disk_capacity   => get_disk_capacity(node),
          :memory_mb       => get_memory_info(node),
          :cpu_total_cores => get_total_cores(node),
          :firmwares       => get_firmwares(node),
          :guest_devices   => get_guest_devices(node)
        }
      end

      def get_disk_capacity(node)
        total_disk_cap = 0
        node.raidSettings&.each do |storage|
          storage['diskDrives']&.each do |disk|
            total_disk_cap += disk['capacity'] unless disk['capacity'].nil?
          end
        end
        total_disk_cap.positive? ? total_disk_cap : nil
      end

      def get_memory_info(node)
        total_memory_gigabytes = node.memoryModules&.reduce(0) { |total, mem| total + mem['capacity'] }
        total_memory_gigabytes * 1024 # convert to megabytes
      end

      def get_total_cores(node)
        node.processors&.reduce(0) { |total, pr| total + pr['cores'] }
      end

      def get_firmwares(node)
        node.firmware&.map { |firmware| parent::FirmwareParser.parse_firmware(firmware) }
      end

      def get_guest_devices(node)
        guest_devices = parent::NetworkDeviceParser.parse_network_devices(node)
        guest_devices.concat(parent::StorageDeviceParser.parse_storage_device(node))
        guest_devices << parse_management_device(node)
      end

      def parse_management_device(node)
        result = parse(node, MANAGEMENT_DEVICE)

        result[:device_type] = "management"
        result[:network][:ipv6address] = node.ipv6Addresses.nil? ? node.ipv6Addresses : node.ipv6Addresses.join(", ")

        result
      end
    end
  end
end
