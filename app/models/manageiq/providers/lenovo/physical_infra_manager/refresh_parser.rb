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

      # The order of the below methods does matter, because there are inner dependencies of the data!
      get_nodes

      $log.info("#{log_header}...Complete")

      @data
    end

    private

    def get_nodes
      nodes = @connection.discover_nodes
      process_collection(nodes, :nodeList) { |node| parse_node(node) }
    end

    def parse_node(node)
      uid    = node.uuid
      type = 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::Node'
      new_result = {
          :type              => type,
          :uid_ems           => uid,
          :ems_ref           => uid,
          :hostname          => node.hostname,
          :mac_address       => node.macAddress,
          :description       => node.description
          # TODO add other properties
      }

      return uid, new_result

    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

  end
end
