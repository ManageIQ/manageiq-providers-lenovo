# rubocop:disable Naming/AccessorMethodName
module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    POWER_STATE_MAP = {
      8  => "on",
      5  => "off",
      18 => "Standby",
      0  => "Unknown"
    }.freeze

    HEALTH_STATE_MAP = {
      "normal"          => "Valid",
      "non-critical"    => "Valid",
      "warning"         => "Warning",
      "critical"        => "Critical",
      "unknown"         => "None",
      "minor-failure"   => "Critical",
      "major-failure"   => "Critical",
      "non-recoverable" => "Critical",
      "fatal"           => "Critical",
      nil               => "Unknown"
    }.freeze

    def initialize(ems, options = nil)
      ems_auth = ems.authentications.first

      @ems               = ems
      @connection        = ems.connect(:user => ems_auth.userid,
                                       :pass => ems_auth.password,
                                       :host => ems.endpoints.first.hostname,
                                       :port => ems.endpoints.first.port)
      @options           = options || {}
      @data              = {}
      @data_index        = {}
      @host_hash_by_name = {}
    end

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id} ref: #{@ems.uid_ems}]"

      $log.info("#{log_header}...")

      get_physical_servers
      discover_ip_physical_infra
      get_config_patterns

      $log.info("#{log_header}...Complete")

      @data
    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

    private

    def get_physical_servers
      nodes = all_server_resources

      nodes = nodes.map do |node|
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| parse_physical_server(node) }
    end

    def get_hardwares(node)
      {
        :memory_mb       => get_memory_info(node),
        :cpu_total_cores => get_total_cores(node),
        :firmwares       => get_firmwares(node),
        :guest_devices   => get_guest_devices(node)
      }
    end

    def get_memory_info(node)
      total_memory = 0
      memory_modules = node.memoryModules
      unless memory_modules.nil?
        memory_modules.each do |mem|
          total_memory += mem['capacity'] * 1024
        end
      end
      total_memory
    end

    def get_total_cores(node)
      total_cores = 0
      processors = node.processors
      unless processors.nil?
        processors.each do |pr|
          total_cores += pr['cores']
        end
      end
      total_cores
    end

    def get_firmwares(node)
      firmwares = node.firmware
      unless firmwares.nil?
        firmwares = firmwares.map do |firmware|
          parse_firmware(firmware)
        end
      end
      firmwares
    end

    def get_guest_devices(node)
      # Retrieve the devices associated with the node
      addin_cards = parse_all_guest_devices(node.addinCards) { |addin_card| parse_addin_cards(addin_card) }
      onboard_devices = parse_all_guest_devices(node.onboardPciDevices) { |onboard_device| parse_onboard_devices(onboard_device) }
      guest_devices = (addin_cards + onboard_devices)

      # Retrieve management devices
      guest_devices.push(parse_management_device(node))

      guest_devices
    end

    def parse_all_guest_devices(node_devices)
      parsed_devices = []

      # For each of the node's devices, parse the device and then see
      # if it is already in the list of parsed devices. If it is, see if
      # all of its ports are already in the existing parsed device entry.
      # If it's not, then add the port to the existing device entry and
      # don't add the device again to the list of parsed devices.
      # This is needed because xclarity_client seems to represent each port
      # as a separate device. The code below ensures that each device
      # is represented by a device with multiple ports.
      unless node_devices.nil?
        node_devices.each do |node_device|
          if get_device_type(node_device) == "ethernet"
            add_device = true
            parsed_node_device = yield(node_device)

            parsed_devices.each do |device|
              if parsed_node_device[:device_name] == device[:device_name]
                if parsed_node_device[:location] == device[:location]
                  parsed_node_device[:child_devices].each do |parsed_port|
                    device_found = false

                    device[:child_devices].each do |port|
                      if parsed_port[:device_name] == port[:device_name]
                        device_found = true
                      end
                    end

                    unless device_found
                      device[:child_devices].push(parsed_port)
                      add_device = false
                    end
                  end
                end
              end
            end

            if add_device
              parsed_devices.push(parsed_node_device)
            end
          end
        end
      end

      parsed_devices
    end

    def get_device_type(device)
      device_type = ""

      unless device["name"].nil?
        device_name = device["name"].downcase
        if device_name.include?("nic") || device_name.include?("ethernet")
          device_type = "ethernet"
        end
      end

      device_type
    end

    def get_guest_device_ports(device)
      device_ports = []

      unless device.nil?
        port_info = device["portInfo"]
        physical_ports = port_info["physicalPorts"]
        unless physical_ports.nil?
          physical_ports.each do |physical_port|
            parsed_physical_port = parse_physical_port(physical_port)
            logical_ports = physical_port["logicalPorts"]
            parsed_logical_port = parse_logical_port(logical_ports[0])
            device_ports.push(parsed_logical_port.merge(parsed_physical_port))
          end
        end
      end

      device_ports
    end

    def get_guest_device_firmware(device)
      device_fw = []

      unless device.nil?
        firmware = device["firmware"]
        unless firmware.nil?
          device_fw = firmware.map do |fw|
            parse_firmware(fw)
          end
        end
      end

      device_fw
    end

    def get_config_patterns
      config_patterns = @connection.discover_config_pattern
      process_collection(config_patterns, :customization_scripts) { |config_pattern| parse_config_pattern(config_pattern) }
    end

    def parse_firmware(firmware)
      {
        :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}",
        :build        => firmware["build"],
        :version      => firmware["version"],
        :release_date => firmware["date"],
      }
    end

    def parse_management_device(node)
      {
        :device_type => "management",
        :network     => parse_management_network(node),
        :address     => node.macAddress
      }
    end

    def parse_management_network(node)
      {
        :ipaddress   => node.mgmtProcIPaddress,
        :ipv6address => node.ipv6Addresses.nil? ? node.ipv6Addresses : node.ipv6Addresses.join(", ")
      }
    end

    def parse_addin_cards(addin_card)
      {
        :device_name            => addin_card["productName"],
        :device_type            => get_device_type(addin_card),
        :firmwares              => get_guest_device_firmware(addin_card),
        :manufacturer           => addin_card["manufacturer"],
        :field_replaceable_unit => addin_card["FRU"],
        :location               => "Bay #{addin_card['slotNumber']}",
        :child_devices          => get_guest_device_ports(addin_card)
      }
    end

    def parse_onboard_devices(onboard_device)
      {
        :device_name   => onboard_device["name"],
        :device_type   => get_device_type(onboard_device),
        :firmwares     => get_guest_device_firmware(onboard_device),
        :location      => "Onboard",
        :child_devices => get_guest_device_ports(onboard_device)
      }
    end

    def parse_physical_port(port)
      {
        :device_type => "physical_port",
        :device_name => "Physical Port #{port['physicalPortIndex']}"
      }
    end

    def parse_logical_port(port)
      {
        :address => format_mac_address(port["addresses"])
      }
    end

    def format_mac_address(mac_address)
      mac_address.scan(/\w{2}/).join(":")
    end

    def parse_physical_server(node)
      new_result = {
        :type                   => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer",
        :name                   => node.name,
        :ems_ref                => node.uuid,
        :uid_ems                => node.uuid,
        :hostname               => node.hostname,
        :product_name           => node.productName,
        :manufacturer           => node.manufacturer,
        :machine_type           => node.machineType,
        :model                  => node.model,
        :serial_number          => node.serialNumber,
        :field_replaceable_unit => node.FRU,
        :host                   => get_host_relationship(node),
        :power_state            => POWER_STATE_MAP[node.powerStatus],
        :health_state           => HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase],
        :vendor                 => "lenovo",
        :computer_system        => {
          :hardware => {
            :guest_devices => [],
            :firmwares     => [] # Filled in later conditionally on what's available
          }
        },
        :asset_details          => parse_asset_details(node),
        :location_led_state    	=> find_loc_led_state(node.leds)
      }
      new_result[:computer_system][:hardware] = get_hardwares(node)
      return node.uuid, new_result
    end

    def parse_config_pattern(config_pattern)
      new_result =
        {
          :manager_ref  => config_pattern.id,
          :name         => config_pattern.name,
          :description  => config_pattern.description,
          :user_defined => config_pattern.userDefined,
          :in_use       => config_pattern.inUse
        }
      return config_pattern.id, new_result
    end

    def get_host_relationship(node)
      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      Host.find_by(:service_tag => node.serialNumber) ||
        Host.joins(:hardware).find_by('hardwares.serial_number' => node.serialNumber)
    end

    def all_server_resources
      return @all_server_resources if @all_server_resources

      cabinets = @connection.discover_cabinet(:status => "includestandalone")

      nodes = cabinets.map(&:nodeList).flatten
      nodes = nodes.map do |node|
        node["itemInventory"]
      end.flatten

      chassis = cabinets.map(&:chassisList).flatten

      nodes_chassis = chassis.map do |chassi|
        chassi["itemInventory"]["nodes"]
      end.flatten
      nodes_chassis = nodes_chassis.select { |node| node["type"] != "SCU" }

      nodes += nodes_chassis

      @all_server_resources = nodes
    end

    def parse_asset_details(node)
      {
        :contact          => node.contact,
        :description      => node.description,
        :location         => node.location['location'],
        :room             => node.location['room'],
        :rack_name        => node.location['rack'],
        :lowest_rack_unit => node.location['lowestRackUnit'].to_s
      }
    end

    def find_loc_led_state(leds)
      identification_led_names = %w(Identify Identification)
      identification_led = leds.to_a.find { |led| identification_led_names.include?(led["name"]) }
      identification_led.try(:[], "state")
    end

    def discover_ip_physical_infra
      hostname = URI.parse(@ems.hostname).host || URI.parse(@ems.hostname).path
      if @ems.ipaddress.blank?
        resolve_ip_address(hostname, @ems)
      end
      if @ems.hostname_ipaddress?(hostname)
        resolve_hostname(hostname, @ems)
      end
    end

    def resolve_hostname(ipaddress, ems)
      ems.hostname = Resolv.getname(ipaddress)
      $log.info("EMS ID: #{ems.id}" + " Resolved hostname successfully.")
    rescue => err
      $log.warn("EMS ID: #{ems.id}" + " It's not possible resolve hostname of the physical infra, #{err}.")
    end

    def resolve_ip_address(hostname, ems)
      ems.ipaddress = Resolv.getaddress(hostname)
      $log.info("EMS ID: #{ems.id}" + " Resolved ip address successfully.")
    rescue => err
      $log.warn("EMS ID: #{ems.id}" + " It's not possible resolve ip address of the physical infra, #{err}.")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
