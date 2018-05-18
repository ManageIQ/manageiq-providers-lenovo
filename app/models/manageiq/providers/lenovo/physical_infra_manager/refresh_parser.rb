# rubocop:disable Naming/AccessorMethodName
module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    def self.miq_template_type
      parent::Parser::ParserDictionaryConstants::MIQ_TYPES["template"]
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

      get_all_physical_infra
      discover_ip_physical_infra
      get_physical_switches
      get_config_patterns

      $log.info("#{log_header}...Complete")

      @data
    end

    private

    # returns the specific parser based on the version of the appliance
    def init_parser(connection)
      aicc = connection.discover_aicc
      version = aicc.first.appliance['version'] if aicc.present? # getting the appliance version
      self.class.parent::Parser.get_instance(version)
    end

    # Retrieve all physical infrastructure that can be obtained from the LXCA (racks, chassis, servers, switches)
    # as XClarity objects and add it to the +@data+ as a hash.
    def get_all_physical_infra
      @data[:physical_racks]   = []
      @data[:physical_chassis] = []
      @data[:physical_servers] = []

      racks = get_plain_physical_racks
      racks.each do |rack|
        parsed_rack = nil
        # One of the API's racks is a mock to indicate physical chassis and servers that are not inside any rack.
        # This rack has the UUID equals to 'STANDALONE_OBJECT_UUID'
        if rack.UUID != 'STANDALONE_OBJECT_UUID'
          _, parsed_rack = @parser.parse_physical_rack(rack)
          @data[:physical_racks] << parsed_rack
        end

        # Retrieve and parse the servers that are inside the rack, but not inside any chassis.
        rack_servers = get_plain_physical_servers_inside_rack(rack)
        rack_servers.each do |server|
          _, parsed_server = @parser.parse_physical_server(server, find_compliance(server), parsed_rack)
          @data[:physical_servers] << parsed_server
        end

        # Retrieve and parse the chassis that are inside the rack.
        rack_chassis = get_plain_physical_chassis_inside_rack(rack)
        rack_chassis.each do |chassis|
          _, parsed_chassis = @parser.parse_physical_chassis(chassis, parsed_rack)
          @data[:physical_chassis] << parsed_chassis

          # Retrieve and parse the servers that are inside the chassi.
          chassis_servers = get_plain_physical_servers_inside_chassis(chassis)
          chassis_servers.each do |server|
            _, parsed_server = @parser.parse_physical_server(server, find_compliance(server), parsed_rack, parsed_chassis)
            @data[:physical_servers] << parsed_server
          end
        end
      end
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

    # Returns physical servers that are inside a chassis.
    def get_plain_physical_servers_inside_chassis(chassis)
      chassis["nodes"].reject { |node| node["type"] == "SCU" }
    end

    def get_physical_switches
      @all_physical_switches ||= @connection.discover_switches

      process_collection(@all_physical_switches, :physical_switches) do |physical_switch|
        @parser.parse_physical_switch(physical_switch)
      end
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
      process_collection(config_patterns, :customization_scripts) { |config_pattern| @parser.parse_config_pattern(config_pattern) }
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
