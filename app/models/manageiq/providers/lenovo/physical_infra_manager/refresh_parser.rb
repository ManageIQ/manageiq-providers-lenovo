module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::RefreshParser < ManageIQ::Providers::PhysicalInfraManager::RefreshParser

    def self.ems_inv_to_hashes(ems, options = nil)
      new(ems, options).ems_inv_to_hashes
    end

    def initialize(ems, options = nil)
      @ems               = ems
      @connection        = ems.connect
      @data              = {}
      @data_index        = {}
      @host_hash_by_name = {}
    end

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data" \
                   " for EMS name: [#{@ems.name}] id: [#{@ems.id}]"
      $log.info("#{log_header}...")
      # The order of the below methods does matter, because there are inner dependencies of the data!

      get_physical_servers

      $log.info("#{log_header}...Complete")
      @data
    end

    private

    def get_physical_servers
      nodes = @connection.discover_nodes
      process_collection(nodes, :nodeList) { |node| parse_node(node) }
    end

    def parse_node(node)
      node
      physical_server = ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.new(node)

      new_result = {
        :type     => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name     => physical_server.name,
        :ems_ref  => physical_server.uuid,
        :uid_ems  => physical_server.hostname,
      }

      return uid, new_result
    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

    #
    # Helper methods
    #
    def process_collection(collection, key)
      @data[key] ||= []
      return if collection.nil?

      collection.each do |item|
        uid, new_result = yield(item)

        @data[key] << new_result
        @data_index.store_path(key, uid, new_result)
      end
    end

  end
end
