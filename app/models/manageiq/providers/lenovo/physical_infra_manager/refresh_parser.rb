# rubocop:disable Style/AccessorMethodName
module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra
    include ManageIQ::Providers::Lenovo::RefreshHelperMethods

    POWER_STATE_MAP = {
      8  => "on",
      5  => "off",
      18 => "Standby",
      0  => "Unknown"
    }.freeze

    HEALTH_STATE_MAP = {
      "normal"          => "Valid",
      "non-critical"    => "Valid",
      "warning"         => "Warning",
      "critical"        => "Critical",
      "unknown"         => "None",
      "minor-failure"   => "Critical",
      "major-failure"   => "Critical",
      "non-recoverable" => "Critical",
      "fatal"           => "Critical"
    }.freeze

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

    def self.miq_template_type
      "ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template"
    end

    private

    def get_physical_servers
      nodes = all_server_resources

      nodes = nodes.map do |node|
        XClarityClient::Node.new node
      end
      process_collection(nodes, :physical_servers) { |node| parse_physical_server(node) }
    end

    def get_hardwares(node)
      {
        :memory_mb       => get_memory_info(node),
        :cpu_total_cores => get_total_cores(node),
        :firmwares       => get_firmwares(node.firmware)
      }
    end

    def get_memory_info(node)
      total_memory = 0
      node.memoryModules.each do |mem|
        total_memory += mem['capacity'] * 1024
      end
      total_memory
    end

    def get_total_cores(node)
      total_cores = 0
      node.processors.each do |pr|
        total_cores += pr['cores']
      end
      total_cores
    end

    def get_firmwares(node)
      firmwares = node.map do |firmware|
        parse_firmware(firmware)
      end
      firmwares
    end

    def parse_firmware(firmware)
      {
        :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}",
        :build        => firmware["build"],
        :version      => firmware["version"],
        :release_date => firmware["date"],
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
        :computer_system        => {:hardware => {:networks => [], :firmwares => []}},
        :host                   => get_host_relationship(node),
        :power_state            => POWER_STATE_MAP[node.powerStatus],
        :health_state           => HEALTH_STATE_MAP[node.cmmHealthState.downcase],
        :vendor                 => "Lenovo",
        :computer_system        => {
          :hardware             => {
            :networks  => [],
            :firmwares => [] # Filled in later conditionally on what's available
          }
        },
        :location_led_state    	=> find_loc_led_state(node.leds)
      }
      new_result[:computer_system][:hardware] = get_hardwares(node)
      return node.uuid, new_result
    end

    def get_host_relationship(node)
      # Assign a physicalserver and host if server already exists and
      # some host match with physical Server's serial number
      Host.find_by(:service_tag => node.serialNumber)
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

    def find_loc_led_state(leds)
      loc_led_state = ""

      leds.each do |led|
        if led["name"] == "Identify"
          loc_led_state = led["state"]
          break
        end
      end

      loc_led_state
    end
  end
end
