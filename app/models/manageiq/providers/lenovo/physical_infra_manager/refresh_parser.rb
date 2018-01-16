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
      process_collection(config_patterns, :customization_scripts) { |config_pattern| @parser.parse_config_pattern(config_pattern) }
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
