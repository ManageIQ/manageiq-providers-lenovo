module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

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
        Firmware.where(:ph_server_uuid => node["uuid"]).delete_all

        # TODO: (walteraa) see how to save it using process_collection
        node["firmware"].map do |firmware|
          f = Firmware.new parse_firmware(firmware, node["uuid"])
          f.save!
        end
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| parse_nodes(node) }
    end

    def parse_firmware(firmware, uuid)
      new_result = {
        :name           => firmware["name"],
        :build          => firmware["build"],
        :version        => firmware["version"],
        :release_date   => firmware["date"],
        :ph_server_uuid => uuid
      }
    end

    def parse_nodes(node)
      # physical_server = ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.new(node)

      new_result = {
        :type    => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name    => node.name,
        :ems_ref => node.uuid,
        :uid_ems => node.uuid
      }

      return node.uuid, new_result
    end

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end
  end
end
