module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::PhysicalServer < Inventory::Parser::ComponentParser
    # Mapping between fields inside a [XClarityClient::Node] to a [Hash] with symbols of PhysicalServer fields
    PHYSICAL_SERVER = {
      :name            => 'name',
      :ems_ref         => 'uuid',
      :uid_ems         => 'uuid',
      :hostname        => 'hostname',
      :vendor          => :vendor,
      # :type            => :type,
      :power_state     => :power_state,
      :health_state    => :health_state,
      :host            => :host,
      :computer_system => {
        :hardware => {
          :disk_capacity   => :disk_capacity,
          :memory_mb       => :memory_info,
          :cpu_total_cores => :total_cores,
          :firmwares       => nil, #:firmwares,
          :guest_devices   => nil, #:guest_devices
        }
      },
      :asset_detail    => {
        :product_name           => 'productName',
        :manufacturer           => 'manufacturer',
        :machine_type           => 'machineType',
        :model                  => 'model',
        :serial_number          => 'serialNumber',
        :part_number            => 'partNumber',
        :field_replaceable_unit => 'FRU',
        :contact                => 'contact',
        :description            => 'description',
        :location               => 'location.location',
        :room                   => 'location.room',
        :rack_name              => 'location.rack',
        :lowest_rack_unit       => 'location.lowestRackUnit'
      }
    }.freeze

    #
    # @param [InventoryObject] rack       - parsed physical rack data
    # @param [InventoryObject] chassis    - parsed physical chassis data
    #
    def build(node_hash, compliance, rack = nil, chassis = nil)
      node_xclarity, properties = parse_physical_server(node_hash, compliance)

      add_parent(properties, :belongs_to => :physical_rack, :object => rack) if rack
      add_parent(properties, :belongs_to => :physical_chassis, :object => chassis) if chassis

      server = @persister.physical_servers.build(properties)

      build_associations(server, node_xclarity)

      server
    end

    #
    # parse a node object to a hash with physical servers data
    #
    # @param [Hash] node_hash  - hash containing physical server raw data
    # @param [Hash] compliance - parsed compliance applied to this physical server
    #
    # @return [Hash] containing the physical server information
    # TODO: change @param compliance
    def parse_physical_server(node_hash, compliance_policies)
      node_xclarity = XClarityClient::Node.new(node_hash)
      result = parse(node_xclarity, PHYSICAL_SERVER)
      compliance = find_compliance(node_hash, compliance_policies)
      # Keep track of the rack where this server is in, if it is in any rack
      result[:ems_compliance_name] = compliance[:policy_name]
      result[:ems_compliance_status] = compliance[:status]

      [node_xclarity, result]
    end

    private

    def build_associations(server, node_xclarity)
      comp_system = build_computer_system(server)
      build_hardware(comp_system, node_xclarity)
      build_asset_detail(server, node_xclarity)
    end

    def build_hardware(comp_system, node_xclarity)
      hw_hash = parse(node_xclarity, PHYSICAL_SERVER[:computer_system][:hardware])
      hw_hash[:computer_system] = comp_system

      hardware = @persister.physical_server_hardwares.build(hw_hash)

      # associations
      build_firmwares(hardware, node_xclarity)
      build_guest_devices(hardware, node_xclarity)

      hardware
    end

    def build_firmwares(hardware, node_xclarity)
      node_xclarity.firmware&.each do |firmware|
        components(:firmwares).build(firmware,
                                     :physical_server_firmwares,
                                     :belongs_to => :resource,
                                     :object     => hardware)
      end
    end

    def build_guest_devices(hardware, node_xclarity)
      components(:network_devices).build(node_xclarity,
                                         :belongs_to => :hardware,
                                         :object     => hardware)
      components(:storage_devices).build(node_xclarity,
                                         :belongs_to => :hardware,
                                         :object     => hardware)
      components(:management_devices).build(node_xclarity,
                                            :physical_server_management_devices,
                                            :belongs_to => :hardware,
                                            :object     => hardware)
    end

    def build_asset_detail(server, node_xclarity)
      super(server, node_xclarity, PHYSICAL_SERVER[:asset_detail]) do |properties|
        properties.merge!(get_location_led_info(node_xclarity.leds) || {})
      end
    end

    def vendor(_node)
      'lenovo'
    end

    def type(_node)
      'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer'
    end

    def power_state(node)
      POWER_STATE_MAP[node.powerStatus]
    end

    def health_state(node)
      HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
    end

    # Assign a physicalserver and host if server already exists and
    # some host match with physical Server's serial number
    def host(node)
      serial_number = node.serialNumber
      Host.find_by(:service_tag => serial_number) ||
        Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
    end

    def disk_capacity(node)
      total_disk_cap = 0
      node.raidSettings&.each do |storage|
        storage['diskDrives']&.each do |disk|
          total_disk_cap += disk['capacity'] unless disk['capacity'].nil?
        end
      end
      total_disk_cap.positive? ? total_disk_cap : nil
    end

    def memory_info(node)
      total_memory_gigabytes = node.memoryModules&.reduce(0) {|total, mem| total + mem['capacity']}
      total_memory_gigabytes * 1024 # convert to megabytes
    end

    def total_cores(node)
      node.processors&.reduce(0) {|total, pr| total + pr['cores']}
    end

    def find_compliance(node, compliance_policies)
      @compliance_policies_parsed ||= Inventory::Parser::ComponentParser::CompliancePolicy.parse_compliance_policy(compliance_policies)
      @compliance_policies_parsed[node["uuid"]] || Inventory::Parser::ComponentParser::CompliancePolicy.default_compliance_policies
    end
  end
end
