module ManageIQ::Providers::Lenovo
  #TODO Change back to PhysicalInfra Inheritance
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
      nodes = @connection.discover_nodes
      process_collection(nodes, :physical_servers) { |node| parse_nodes(node) }
    end


    def parse_nodes(node)
      node
      # physical_server = ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.new(node)

      new_result = {
        :type     => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name     => node.name,
        :ems_ref  => node.uuid,
        :uid_ems  => node.hostname,
      }

      return node.uuid, new_result
    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

  end
end
