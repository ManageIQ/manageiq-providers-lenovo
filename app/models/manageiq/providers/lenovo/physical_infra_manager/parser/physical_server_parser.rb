module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalServerParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
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
        result = parse(node, parent::ParserDictionaryConstants::PHYSICAL_SERVER)

        # Keep track of the rack where this server is in, if it is in any rack
        result[:physical_rack]              = rack if rack
        result[:physical_chassis]           = chassis if chassis
        result[:ems_compliance_name]        = compliance[:policy_name]
        result[:ems_compliance_status]      = compliance[:status]
        result[:vendor]                     = "lenovo"
        result[:type]                       = parent::ParserDictionaryConstants::MIQ_TYPES["physical_server"]
        result[:power_state]                = parent::ParserDictionaryConstants::POWER_STATE_MAP[node.powerStatus]
        result[:health_state]               = parent::ParserDictionaryConstants::HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
        result[:host]                       = get_host_relationship(node.serialNumber)
        result[:location_led_state]         = find_loc_led_state(node.leds)
        result[:computer_system][:hardware] = get_hardwares(node)

        return node.uuid, result
      end

      private

      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      def get_host_relationship(serial_number)
        Host.find_by(:service_tag => serial_number) ||
          Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
      end

      # Find the identification led state
      def find_loc_led_state(leds)
        identification_led = leds.to_a.find { |led| parent::ParserDictionaryConstants::PROPERTIES_MAP[:led_identify_name].include?(led["name"]) }
        identification_led.try(:[], "state")
      end

      def get_hardwares(node)
        {
          :disk_capacity   => get_disk_capacity(node),
          :memory_mb       => get_memory_info(node),
          :cpu_total_cores => get_total_cores(node),
          :firmwares       => get_firmwares(node),
          :guest_devices   => get_guest_devices(node),
          :networks        => get_networks(node),
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
      end

      def parse_network(assignment, is_ipv6 = false)
        result = parse(assignment, parent::ParserDictionaryConstants::PHYSICAL_SERVER_NETWORK)

        result[:ipaddress]   = assignment['address'] unless is_ipv6
        result[:ipv6address] = assignment['address'] if is_ipv6

        result
      end

      def get_networks(node)
        get_parsed_switch_ip_interfaces_by_key(
          node.ipInterfaces,
          'IPv4assignments',
          node.ipv4Addresses,
          false
        ) + get_parsed_switch_ip_interfaces_by_key(
          node.ipInterfaces,
          'IPv6assignments',
          node.ipv6Addresses,
          true
        )
      end

      def get_parsed_switch_ip_interfaces_by_key(ip_interfaces, key, address_list, is_ipv6 = false)
        ip_interfaces&.flat_map { |interface| interface[key] }
          .select { |assignment| address_list.include?(assignment['address']) }
          .map { |assignment| parse_network(assignment, is_ipv6) }
      end
    end
  end
end
