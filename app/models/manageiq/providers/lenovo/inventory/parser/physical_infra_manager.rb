module ManageIQ::Providers::Lenovo
  class Inventory::Parser::PhysicalInfraManager < ::ManageIQ::Providers::Lenovo::Inventory::Parser
    def parse
      physical_racks do |persister_rack, rack|
        # Retrieve and parse the servers that are inside the rack, but not inside any chassis.
        physical_servers_inside_rack(persister_rack, rack)
        # Retrieve and parse the chassis that are inside the rack.
        physical_chassis_inside_rack(persister_rack, rack) do |persister_chassis, chassis_hash|
          # Retrieve and parse the servers that are inside the chassi.
          physical_server_inside_chassis(persister_rack, persister_chassis, chassis_hash)
          # Retrieve and parse the storages that are inside the chassis
          physical_storages_inside_chassis(persister_chassis)
        end
        # Retrieve and parse storages that are inside the rack.
        physical_storages_inside_rack(persister_rack, rack)
      end

      # This parses all storages disassociated to others components (such as racks or chassis)
      physical_storages_unassociated

      # Retrieve and parse the switches
      physical_switches

      customization_scripts

      components(:physical_network_ports).bind_network_ports!
    end

    def components(name)
      @components ||= {}
      if @components[name].nil?
        klass = "ManageIQ::Providers::Lenovo::Inventory::Parser::ComponentParser::#{name.to_s.classify}"
        raise "Parser class #{klass} doesn't exist!" if klass != klass.safe_constantize.to_s
        @components[name] = klass.safe_constantize.new(persister, self)
      end
      @components[name]
    end

    def physical_racks
      collector.physical_racks.each do |physical_rack|
        persister_rack = if physical_rack.UUID != 'STANDALONE_OBJECT_UUID'
                           components(:physical_racks).build(physical_rack)
                         end

        yield persister_rack, physical_rack
      end
    end

    def parent_physical_storages
      return @parent_storages if @parent_storages.present?

      @parent_storages = {}
      collector.physical_storages&.each do |storage|
        parent_uuid = storage.parent['uuid']

        @parent_storages[parent_uuid] = [] if @parent_storages[parent_uuid].nil?
        @parent_storages[parent_uuid] << storage
      end
      @parent_storages
    end

    def physical_servers_inside_rack(persister_rack, rack_hash)
      collector.physical_servers_inside_rack(rack_hash).each do |server_hash|
        components(:physical_servers).build(server_hash, collector.compliance_policies, persister_rack)
      end
    end

    def physical_chassis_inside_rack(persister_rack, rack_hash)
      collector.physical_chassis_inside_rack(rack_hash).each do |chassis_hash|
        persister_chassis = components(:physical_chassis).build(chassis_hash, persister_rack)

        yield persister_chassis, chassis_hash
      end
    end

    def physical_server_inside_chassis(persister_rack, persister_chassis, chassis_hash)
      collector.physical_servers_inside_chassis(chassis_hash).each do |server_hash|
        components(:physical_servers).build(server_hash, collector.compliance_policies, persister_rack, persister_chassis)
      end
    end

    def physical_storages_inside_chassis(persister_chassis)
      chassis_storages = parent_physical_storages.delete(persister_chassis.uid_ems)
      chassis_storages&.each do |storage_xclarity|
        components(:physical_storages).build(storage_xclarity, nil, persister_chassis)
      end
    end

    def physical_storages_inside_rack(persister_rack, rack_xclarity)
      rack_storages = parent_physical_storages.delete(rack_xclarity.UUID)
      rack_storages&.each do |storage_xclarity|
        components(:physical_storages).build(storage_xclarity, persister_rack)
      end
    end

    def physical_storages_unassociated
      parent_physical_storages.values.flatten.each do |storage_xclarity|
        components(:physical_storages).build(storage_xclarity)
      end
    end

    def physical_switches
      collector.physical_switches.each do |switch_xclarity|
        components(:physical_switches).build(switch_xclarity)
      end
    end

    def customization_scripts
      collector.config_patterns.each do |config_pattern|
        components(:config_patterns).build(config_pattern)
      end
    end
  end
end
