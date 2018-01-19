# rubocop:disable Naming/AccessorMethodName
module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    require_relative './parsers/parser'
    require_relative './parsers/parser_dictionary_constants'

    def self.miq_template_type
      ManageIQ::Providers::Lenovo::ParserDictionaryConstants::MIQ_TYPES["template"]
    end

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
      @parser            = init_parser(@connection)
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

    private

    # returns the specific parser based on the version of the appliance
    def init_parser(connection)
      version = connection.discover_aicc.first.appliance['version'] # getting the appliance version
      ManageIQ::Providers::Lenovo::Parser.get_instance(version)
    end

    def get_physical_servers
      nodes = all_server_resources

      nodes = nodes.map do |node|
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| @parser.parse_physical_server(node) }
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
