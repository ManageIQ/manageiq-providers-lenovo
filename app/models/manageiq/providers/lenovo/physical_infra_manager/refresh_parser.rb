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
      get_config_patterns

      $log.info("#{log_header}...Complete")

      @data
    end

    private

    # returns the specific parser based on the version of the appliance
    def init_parser(connection)
      version = connection.discover_aicc.first.appliance['version'] # getting the appliance version
      self.class.parent::Parser.get_instance(version)
    end

    # Retrieve all physical infrastructure that can be obtained from the LXCA (racks, chassis, servers, switches)
    # as XClarity objects and add it to the +@data+ as a hash.
    def get_all_physical_infra
      cabinets = get_physical_racks

      # Retrieve the standalone rack (mock of a rack) so it is possible to retrieve all components
      # from it and associate with the provider instead a mock rack.
      standalone = nil
      cabinets.reverse_each do |cab|
        if cab.UUID == 'STANDALONE_OBJECT_UUID'
          standalone = cabinets.delete(cab)
          break
        end
      end

      physical_servers = []
      process_collection(cabinets, :physical_racks) do |cab|
        rack_uid, rack = @parser.parse_physical_rack(cab)

        get_physical_servers(cab) do |node|
          _, parsed = @parser.parse_physical_server(node, rack)
          physical_servers << parsed
        end

        next rack_uid, rack
      end

      nodes = get_physical_servers(standalone)
      process_collection(nodes, :physical_servers) do |node|
        @parser.parse_physical_server(node)
      end

      @data[:physical_servers].concat(physical_servers)
    end

    # Returns all physical rack from the api.
    def get_physical_racks
      @connection.discover_cabinet(:status => "includestandalone")
    end

    # Create a XClarity Node object for every node in a rack.
    #
    # @param cabinet [PhysicalRack] The rack from where it will retrieve the physical servers.
    #
    # Yields a XClarity Node object.
    # @return [Hash] a parsed hash for every PhysicalServer that belongs to the cabinet.
    def get_physical_servers(cabinet)
      return if cabinet.nil?
      chassis = cabinet.chassisList

      nodes_chassis = chassis.map do |chassi|
        chassi["itemInventory"]["nodes"]
      end.flatten
      nodes_chassis = nodes_chassis.reject { |node| node["type"] == "SCU" }

      nodes = cabinet.nodeList
      nodes = nodes.map { |node| node["itemInventory"] }

      nodes += nodes_chassis

      nodes.map do |node|
        xc_node = XClarityClient::Node.new(node)
        yield(xc_node) if block_given?
        xc_node
      end
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
