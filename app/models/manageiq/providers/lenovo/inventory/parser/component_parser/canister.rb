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

        build_associations(parent[:object], canister, data[:raw_data])
      end
    end

    private

    # @param canister [InventoryObject]
    # @param canister_raw_data [Hash]
    def build_associations(storage, canister, canister_raw_data)
      comp_system = build_computer_system(canister)
      build_hardware(comp_system, canister_raw_data)
      build_physical_disks(storage, canister, canister_raw_data)
    end

    def build_hardware(comp_system, canister_raw_data)
      hw = @persister.physical_storage_hardwares.build(
        :computer_system => comp_system
      )

      build_firmwares(hw, canister_raw_data) if canister_raw_data['firmware'].present?
      build_guest_devices(hw, canister_raw_data) if canister_raw_data['networkPorts'].present?
    end

    def build_firmwares(hardware, canister_properties)
      components(:firmwares).build_for_canister(canister_properties['firmware'],
                                                :canister_firmwares,
                                                :belongs_to => :resource,
                                                :object     => hardware)
    end

    def build_guest_devices(hardware, canister_properties)
      components(:management_devices).build_for_canister(canister_properties,
                                                         hardware,
                                                         :belongs_to => :hardware,
                                                         :object     => hardware)
    end

    def build_physical_disks(storage, canister, canister_raw_data)
      driver_index = 0
      canister_raw_data.[]('drives')&.each do |drive|
        components(:physical_disks).build(drive, driver_index.to_s, storage, canister)
        driver_index += 1
      end
    end

    def parse_canisters_inside_components(components)
      canisters = []
      canister_index = 0
      components.each do |component|
        component['canisters'].each do |canister|
          canisters << { :parsed_canister => parse_canister(canister, canister_index),
                         :raw_data        => canister }
          canister_index += 1
        end
      end
      canisters
    end

    def parse_canisters_inside_storage(storage)
      canisters = []
      canister_index = 0
      storage.canisters.each do |canister|
        canisters << { :parsed_canister => parse_canister(canister, canister_index),
                       :raw_data        => canister }
        canister_index += 1
      end
      canisters
    end

    def parse_canister(canister, canister_index)
      result = {}
      CANISTER.each_pair do |key, canister_key|
        next unless canister_key.kind_of?(String)

        result[key] = canister[canister_key]
      end
      result[:ems_ref] = (canister['uuid'] || '') + '_' + canister_index.to_s

      result
    end
  end
end
