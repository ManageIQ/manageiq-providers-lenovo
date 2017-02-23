module ManageIQ::Providers::Lenovo
  # TODO: Change back to PhysicalInfra Inheritance
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    def initialize(ems, options = nil)
      ems_auth = ems.authentications.first

      @ems               = ems
      @connection        = ems.connect({:user => ems_auth.userid,
                                        :pass => ems_auth.password,
                                        :host =>  ems.endpoints.first.hostname})
      @options           = options || {}
      @data              = {}
      @data_index        = {}
      @host_hash_by_name = {}
    end

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS : [#{@ems.name}] id: [#{@ems.id}]"

      $log.info("#{log_header}...")

      get_physical_servers

      $log.info("#{log_header}...Complete")

      @data
    end

    private

    def get_physical_servers
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

      nodes = nodes.map do |node|
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| parse_nodes(node) }
    end


    def parse_nodes(node)
      # physical_server = ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.new(node)

      new_result = {
        :type          => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name          => node.name,
        :ems_ref       => node.uuid,
        :uid_ems       => @ems.uid_ems,
        :hostname      => node.hostname,
        :product_name  => node.productName,
        :manufacturer  => node.manufacturer,
        :machine_type  => node.machineType,
        :model         => node.model,
        :serial_number => node.serialNumber,
        :uuid          =>  node.uuid,
        :FRU           =>  node.FRU,
        :macAddresses  => node.macAddress.split(",").flatten,
        :ipv4Addresses => node.ipv4Addresses.split.flatten,
        :ipv6Addresses => node.ipv6Addresses.split.flatten      
      }

      return node.uuid, new_result
    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

  end
end
