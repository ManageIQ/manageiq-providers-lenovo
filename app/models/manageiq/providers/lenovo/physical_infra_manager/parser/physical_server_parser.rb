module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalServerParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      # Mapping between fields inside a [XClarityClient::Node] to a [Hash] with symbols of PhysicalServer fields
      PHYSICAL_SERVER = {
        :name               => 'name',
        :ems_ref            => 'uuid',
        :uid_ems            => 'uuid',
        :hostname           => 'hostname',
        :vendor             => :vendor,
        :type               => :type,
        :power_state        => :power_state,
        :health_state       => :health_state,
        :host               => :host,
        :location_led_state => :location_led_state,
        :computer_system    => {
          :hardware => {
            :disk_capacity   => :disk_capacity,
            :memory_mb       => :memory_info,
            :cpu_total_cores => :total_cores,
            :firmwares       => :firmwares,
            :guest_devices   => :guest_devices
          },
        },
        :asset_detail       => {
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
          :lowest_rack_unit       => 'location.lowestRackUnit',
        },
      }.freeze

      #
      # parse a node object to a hash with physical servers data
      #
      # @param [Hash] node_hash  - hash containing physical server raw data
      # @param [Hash] compliance - parsed compliance applied to this physical server
      # @param [Hash] rack       - parsed physical rack data
      # @param [Hash] chassis    - parsed physical chassis data
      #
      # @return [Hash] containing the physical server information
      #
      def parse_physical_server(node_hash, compliance, rack = nil, chassis = nil)
        node = XClarityClient::Node.new(node_hash)
        result = parse(node, PHYSICAL_SERVER)

        # Keep track of the rack where this server is in, if it is in any rack
        result[:physical_rack]              = rack if rack
        result[:physical_chassis]           = chassis if chassis
        result[:ems_compliance_name]        = compliance[:policy_name]
        result[:ems_compliance_status]      = compliance[:status]

        result
      end

      private

      def vendor(_node)
        'lenovo'
      end

      def type(_node)
        'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer'
      end

      def power_state(node)
        POWER_STATE_MAP[node.powerStatus]
      end

      def health_state(node)
        HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
      end

      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      def host(node)
        serial_number = node.serialNumber
        Host.find_by(:service_tag => serial_number) ||
          Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
      end

      # Find the identification led state
      def location_led_state(node)
        identification_led = node.leds.to_a.find { |led| PROPERTIES_MAP[:led_identify_name].include?(led['name']) }
        identification_led.try(:[], 'state')
      end

      def disk_capacity(node)
        total_disk_cap = 0
        node.raidSettings&.each do |storage|
          storage['diskDrives']&.each do |disk|
            total_disk_cap += disk['capacity'] unless disk['capacity'].nil?
          end
        end
        total_disk_cap.positive? ? total_disk_cap : nil
      end

      def memory_info(node)
        total_memory_gigabytes = node.memoryModules&.reduce(0) { |total, mem| total + mem['capacity'] }
        total_memory_gigabytes * 1024 # convert to megabytes
      end

      def total_cores(node)
        node.processors&.reduce(0) { |total, pr| total + pr['cores'] }
      end

      def firmwares(node)
        node.firmware&.map { |firmware| parent::FirmwareParser.parse_firmware(firmware) }
      end

      def guest_devices(node)
        guest_devices = parent::NetworkDeviceParser.parse_network_devices(node)
        guest_devices.concat(parent::StorageDeviceParser.parse_storage_device(node))
        guest_devices << parent::ManagementDeviceParser.parse_management_device(node)
      end
    end
  end
end
