# rubocop:disable Style/AccessorMethodName
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
      "fatal"           => "Critical"
    }.freeze

    def initialize(ems, options = nil)
      ems_auth = ems.authentications.first

      @ems               = ems
      @connection        = ems.connect(:user => ems_auth.userid,
                                       :pass => ems_auth.password,
                                       :host => ems.endpoints.first.hostname)
      @options           = options || {}
      @data              = {}
      @data_index        = {}
      @host_hash_by_name = {}
    end

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id} ref: #{@ems.uid_ems}]"

      $log.info("#{log_header}...")

      get_physical_servers

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
      node.memoryModules.each do |mem|
        total_memory += mem['capacity'] * 1024
      end
      total_memory
    end

    def get_total_cores(node)
      total_cores = 0
      node.processors.each do |pr|
        total_cores += pr['cores']
      end
      total_cores
    end

    def get_firmwares(node)
      firmwares = node.firmware.map do |firmware|
        parse_firmware(firmware)
      end
      firmwares
    end

    def get_guest_devices_firmwares(addin_card)
      dev_fw = []

      if addin_card != nil
        firmwares = addin_card["firmware"]
        if (firmwares != nil)
          dev_fw = firmwares.map do |fw|
            parse_firmware(fw)
          end
        end
      end

      dev_fw
    end

    def get_guest_devices_ports(addin_card)
      dev_ports = []
      if addin_card != nil
        port_info = addin_card["portInfo"]
        physical_ports = port_info["physicalPorts"]
        if physical_ports != nil
          physical_ports.each do |physical_port|
            parsed_physical_port = parse_physical_port(physical_port)
            logical_ports = physical_port["logicalPorts"]
            parsed_logical_port = parse_logical_port(logical_ports[0])
            dev_ports.push(parsed_logical_port.merge(parsed_physical_port))
          end
        end
      end

      dev_ports
    end

    def get_guest_devices(node)
      addin_cards = get_addin_cards(node)

      guest_devices = addin_cards.map do |addin_card|
        addin_card
      end

      guest_devices.push(parse_ethernet_device(node))

      onboard_cards = get_onboard_cards(node)
      guest_devices = (guest_devices + onboard_cards)

      guest_devices
    end

    def get_network(node)
      {
        :ipaddress   => node.mgmtProcIPaddress,
        :ipv6address => node.ipv6Addresses.join(", ")
      }
    end

    def get_addin_cards(node)
      node_addin_cards = node.addinCards
      addin_cards = []

      if (node_addin_cards != nil)
        node_addin_cards.each do |addin_card|
          if get_device_type(addin_card) == "ethernet"
            addin_cards.push(parse_addin_cards(addin_card))
          end
        end
      end

      addin_cards
    end

    def get_onboard_cards(node)
      node_onboard_cards = node.onboardPciDevices
      onboard_cards = []

      if (node_onboard_cards != nil)
        node_onboard_cards.each do |onboard_card|
          if get_device_type(onboard_card) == "ethernet"
            onboard_cards.push(parse_onboard_cards(onboard_card))
          end
        end
      end

      onboard_cards
    end

    def get_device_type(addin_card)
      device_type = ""
      card_name = addin_card["name"].downcase

      if card_name.include?("nic") || card_name.include?("ethernet")
        device_type = "ethernet"
      end

      device_type
    end

    def parse_ethernet_device(node)
      {
        :device_type => "ethernet",
        :network     => get_network(node),
        :address     => node.macAddress
      }
    end

    def parse_firmware(firmware)
      {
        :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}",
        :build        => firmware["build"],
        :version      => firmware["version"],
        :release_date => firmware["date"],
      }
    end

    def parse_addin_cards(addin_card)
      {
        :device_name  => addin_card["productName"],
        :device_type =>  get_device_type(addin_card),
        :firmwares    => get_guest_devices_firmwares(addin_card),
        :manufacturer => addin_card["manufacturer"],
        :field_replaceable_unit => addin_card["FRU"],
        :location     => addin_card["slotNumber"],
        :guest_devices => get_guest_devices_ports(addin_card)
      }
    end

    def parse_onboard_cards(onboard_card)
      {
        :device_name  => onboard_card["name"],
        :device_type  => get_device_type(onboard_card),
        :firmwares    => get_guest_devices_firmwares(onboard_card),
        :guest_devices => get_guest_devices_ports(onboard_card)
      }
    end

    def parse_physical_port(port)
      {
        :device_type => "ethernet port",
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
        :type                   => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name                   => node.name,
        :ems_ref                => node.uuid,
        :uid_ems                => @ems.uid_ems,
        :hostname               => node.hostname,
        :product_name           => node.productName,
        :manufacturer           => node.manufacturer,
        :machine_type           => node.machineType,
        :model                  => node.model,
        :serial_number          => node.serialNumber,
        :field_replaceable_unit => node.FRU,
        :host                   => get_host_relationship(node),
        :power_state            => POWER_STATE_MAP[node.powerStatus],
        :health_state           => HEALTH_STATE_MAP[node.cmmHealthState.downcase],
        :vendor                 => "lenovo",
        :computer_system        => {
          :hardware             => {
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

    def get_host_relationship(node)
      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      Host.find_by(:service_tag => node.serialNumber)
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
      loc_led_state = ""

      leds.each do |led|
        if led["name"] == "Identify"
          loc_led_state = led["state"]
          break
        end
      end

      loc_led_state
    end
  end
end
