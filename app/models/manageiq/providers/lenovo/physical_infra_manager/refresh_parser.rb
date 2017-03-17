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

      # get_firmwares
      get_physical_servers
      get_hardwares

      $log.info("#{log_header}...Complete")

      @data
    end

    private

    def get_hardwares
      # hardware = host_inv_to_hardware_hash(host_inv)
      # hardware[:guest_devices], guest_device_uids[mor] = host_inv_to_guest_device_hashes(host_inv, switch_uids[mor])
      # hardware[:networks] = host_inv_to_network_hashes(host_inv, guest_device_uids[mor])
    end

    def get_firmwares
      nodes = all_server_resources

      nodes = nodes.map do |node|
        Firmware.where(:ph_server_uuid => node["uuid"]).delete_all
        node["firmware"].map do |firmware|
          f = Firmware.new parse_firmware(firmware, node["uuid"])
          f.save!
        end
        XClarityClient::Node.new node
      end
      process_collection(nodes, :firmwares) { |node| parse_firmware(node) }
    end

    def get_physical_servers
      nodes = all_server_resources

      nodes = nodes.map do |node|
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| parse_physical_server(node) }
    end

    def parse_firmware(firmware, uuid)
      {
        :name           => firmware["name"],
        :build          => firmware["build"],
        :version        => firmware["version"],
        :release_date   => firmware["date"],
        :ph_server_uuid => uuid
      }
    end

    def parse_physical_server(node)
      new_result = {
        :type                   => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.name,
        :name                   => node.name,
        :ems_ref                => node.uuid,
        :uid_ems                => @ems.uid_ems,
        :hostname               => node.hostname,
        :product_name           => node.productName,
        :manufacturer           => node.manufacturer,
        :machine_type           => node.machineType,
        :model                  => node.model,
        :serial_number          => node.serialNumber,
        :field_replaceable_unit => node.FRU,
        # :macAddresses  => node.macAddress.split(",").flatten,
        # :ipv4Addresses => node.ipv4Addresses.split.flatten,
        # :ipv6Addresses => node.ipv6Addresses.split.flatten
      }
      return node.uuid, new_result
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

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end
  end
end
