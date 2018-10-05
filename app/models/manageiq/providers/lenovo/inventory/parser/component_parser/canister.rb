module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::Canister < Inventory::Parser::ComponentParser
    # TODO(mslemr) no UUID in this list, but canister has UUID
    # http://sysmgt.lenovofiles.com/help/index.jsp?topic=%2Fcom.lenovo.lxca_restapis.doc%2Frest_apis_reference.html
    CANISTER = {
      :serial_number                => 'serialNumber',
      :name                         => 'cmmDisplayName',
      :position                     => 'position',
      :status                       => 'status',
      :health_state                 => 'health',
      :disk_bus_type                => 'diskBusType',
      :phy_isolation                => 'phyIsolation',
      :controller_redundancy_status => 'controllerRedundancyStatus',
      :disks                        => 'disks',
      :disk_channel                 => 'diskChannel',
      :system_cache_memory          => 'systemCacheMemory',
      :power_state                  => 'powerState',
      :host_ports                   => 'hostPorts',
      :hardware_version             => 'hardwareVersion',
      :computer_system              => {
        :hardware => {
          :firmwares     => nil,
          :guest_devices => {
            :physical_network_port => nil
          }
        }
      }
    }.freeze

    def build(storage_xclarity, parent)
      canisters = if storage_xclarity.enclosures.present?
                    parse_canisters_inside_components(storage_xclarity.enclosures)
                  else
                    parse_canisters_inside_storage(storage_xclarity)
                  end

      canisters.each do |data|
        add_parent(data[:parsed_canister], parent)

        canister = @persister.canisters.build(data[:parsed_canister])

        build_associations(canister, data[:raw_data])
      end
    end

    private

    # @param canister [InventoryObject]
    # @param canister_raw_data [Hash]
    def build_associations(canister, canister_raw_data)
      comp_system = build_computer_system(canister)
      build_hardware(comp_system, canister_raw_data)
    end

    def build_hardware(comp_system, canister_raw_data)
      hw = @persister.physical_storage_hardwares.build(
        :computer_system => comp_system
      )

      build_firmwares(hw, canister_raw_data)

      build_guest_devices(hw, canister_raw_data) if canister_raw_data['networkPorts'].present?
    end

    def build_firmwares(hardware, canister_raw_data)
      firmware = canister_raw_data['firmware']
      if firmware.present? && firmware['storageControllerCpuType'] != 'Not Present'
        components(:firmware).build(firmware,
                                    :physical_storage_firmwares,
                                    :belongs_to => :resource,
                                    :object     => hardware)
      end
    end

    def build_guest_devices(hardware, canister_properties)
      components(:management_devices).build_for_canister(canister_properties,
                                                         hardware,
                                                         :belongs_to => :hardware,
                                                         :object     => hardware)
    end

    def parse_canisters_inside_components(components)
      canisters = []
      components.each do |component|
        component['canisters'].each do |canister|
          canisters << { :parsed_canister => parse_canister(canister),
                         :raw_data        => canister }
        end
      end
      canisters
    end

    def parse_canisters_inside_storage(storage)
      canisters = []
      storage.canisters.each do |canister|
        canisters << { :parsed_canister => parse_canister(canister),
                       :raw_data        => canister }
      end
      canisters
    end

    def parse_canister(canister)
      result = {}
      CANISTER.each_pair do |key, canister_key|
        next unless canister_key.kind_of?(String)

        result[key] = canister[canister_key]
      end
      result
    end
  end
end
