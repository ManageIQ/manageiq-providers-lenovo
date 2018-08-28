# rubocop:disable Naming/AccessorMethodName
module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    def initialize(ems, _options = nil)
      ems_auth = ems.authentications.first

      @ems        = ems
      @connection = ems.connect(:user => ems_auth.userid,
                                :pass => ems_auth.password,
                                :host => ems.endpoints.first.hostname,
                                :port => ems.endpoints.first.port)
      @parser     = init_parser(@connection)
    end

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id} ref: #{@ems.uid_ems}]"

      $log.info("#{log_header}...")

      inventory                         = get_all_physical_infra
      inventory[:physical_switches]     = get_physical_switches
      inventory[:customization_scripts] = get_config_patterns

      bind_network_ports(inventory)

      $log.info("#{log_header}...Complete")

      inventory
    end

    private

    # returns the specific parser based on the version of the appliance
    def init_parser(connection)
      aicc = connection.discover_aicc
      version = aicc.first.appliance['version'] if aicc.present? # getting the appliance version
      self.class.parent::Parser.get_instance(version)
    end

    # Retrieve all physical infrastructure that can be obtained from the LXCA (racks, chassis, servers, switches)
    # as XClarity objects.
    def get_all_physical_infra
      inventory = {}
      inventory[:physical_racks]    = []
      inventory[:physical_chassis]  = []
      inventory[:physical_servers]  = []
      inventory[:physical_storages] = []

      racks = get_plain_physical_racks
      racks.each do |rack|
        parsed_rack = nil
        # One of the API's racks is a mock to indicate physical chassis and servers that are not inside any rack.
        # This rack has the UUID equals to 'STANDALONE_OBJECT_UUID'
        if rack.UUID != 'STANDALONE_OBJECT_UUID'
          parsed_rack = @parser.parse_physical_rack(rack)
          inventory[:physical_racks] << parsed_rack
        end

        # Retrieve and parse the servers that are inside the rack, but not inside any chassis.
        rack_servers = get_plain_physical_servers_inside_rack(rack)
        rack_servers.each do |server|
          parsed_server = @parser.parse_physical_server(server, find_compliance(server), parsed_rack)
          inventory[:physical_servers] << parsed_server
        end

        # Retrieve and parse the chassis that are inside the rack.
        rack_chassis = get_plain_physical_chassis_inside_rack(rack)
        rack_chassis.each do |chassis|
          parsed_chassis = @parser.parse_physical_chassis(chassis, parsed_rack)
          inventory[:physical_chassis] << parsed_chassis

          # Retrieve and parse the servers that are inside the chassi.
          chassis_servers = get_plain_physical_servers_inside_chassis(chassis)
          chassis_servers.each do |server|
            parsed_server = @parser.parse_physical_server(server, find_compliance(server), parsed_rack, parsed_chassis)
            inventory[:physical_servers] << parsed_server
          end

          # Retrieve and parse the storages that are inside the chassis
          chassis_storages = get_plain_physical_storages_inside_chassis(chassis)
          chassis_storages.each do |storage|
            parsed_storage = @parser.parse_physical_storage(storage, parsed_rack, parsed_chassis)
            inventory[:physical_storages] << parsed_storage
          end
        end

        # Retrieve and parse storages that are inside the rack.
        rack_storages = get_plain_physical_storages_inside_rack(rack)
        rack_storages.each do |storage|
          parsed_storage = @parser.parse_physical_storage(storage, parsed_rack)
          inventory[:physical_storages] << parsed_storage
        end
      end

      inventory
    end

    # Returns all physical rack from the api.
    def get_plain_physical_racks
      @connection.discover_cabinet(:status => "includestandalone")
    end

    # Returns physical servers that are inside a rack but not inside a chassis.
    def get_plain_physical_servers_inside_rack(rack)
      rack.nodeList.map { |node| node["itemInventory"] }
    end

    # Returns physical chassis that are inside a rack.
    def get_plain_physical_chassis_inside_rack(rack)
      rack.chassisList.map { |chassis| chassis["itemInventory"] }
    end

    # Returns physical storages that are inside a rack.
    def get_plain_physical_storages_inside_rack(rack)
      rack.storageList.map { |storage| storage["itemInventory"] }
    end

    # Returns physical storages that are inside a chassis.
    def get_plain_physical_storages_inside_chassis(chassis)
      chassis["nodes"].select { |node| node["type"] == "SCU" && node["canisterSlots"].present? }
    end

    # Returns physical servers that are inside a chassis.
    def get_plain_physical_servers_inside_chassis(chassis)
      chassis["nodes"].reject { |node| node["type"] == "SCU" }
    end

    def get_physical_switches
      switches = @connection.discover_switches
      switches.map { |switch| @parser.parse_physical_switch(switch) }
    end

    def find_compliance(node)
      @compliance_policies ||= @connection.fetch_compliance_policies
      @compliance_policies_parsed ||= @parser.parse_compliance_policy(@compliance_policies)
      @compliance_policies_parsed[node["uuid"]] || create_default_compliance
    end

    def create_default_compliance
      {
        :policy_name => PhysicalInfraManager::Parser::CompliancePolicyParser::COMPLIANCE_NAME,
        :status      => PhysicalInfraManager::Parser::CompliancePolicyParser::COMPLIANCE_STATUS['']
      }
    end

    def get_config_patterns
      config_patterns = @connection.discover_config_pattern
      config_patterns.map { |config_pattern| @parser.parse_config_pattern(config_pattern) }
    end

    def bind_network_ports(inventory)
      physical_servers = inventory[:physical_servers]
      physical_switches = inventory[:physical_switches]

      ports = []

      ports.concat(PhysicalInfraManager::Parser::PhysicalNetworkPortsParser.extract_physical_servers_ports(physical_servers))
      ports.concat(PhysicalInfraManager::Parser::PhysicalNetworkPortsParser.extract_physical_switches_ports(physical_switches))

      PhysicalInfraManager::Parser::PhysicalNetworkPortsParser.bind_network_ports!(ports)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
