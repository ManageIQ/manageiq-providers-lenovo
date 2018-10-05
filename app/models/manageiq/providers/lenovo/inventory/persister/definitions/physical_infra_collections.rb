module ManageIQ::Providers::Lenovo::Inventory::Persister::Definitions::PhysicalInfraCollections
  extend ActiveSupport::Concern

  def initialize_physical_infra_inventory_collections
    %i(canisters
       customization_scripts
       physical_disks
       physical_chassis
       physical_racks
       physical_servers
       physical_storages
       physical_switches).each do |name|

      add_collection(physical_infra, name)
    end

    add_asset_details

    add_computer_systems

    add_computer_system_hardwares
    add_physical_switch_hardwares

    add_firmwares

    add_physical_server_network_devices
    add_physical_server_storage_adapters

    add_management_devices

    add_management_device_networks
    add_physical_switch_networks

    add_physical_network_ports
  end

  # ------ IC provider specific definitions -------------------------
  def add_asset_details
    %i(physical_server
       physical_chassis
       physical_storage
       physical_switch).each do |asset_detail_assoc|

      add_collection(physical_infra, "#{asset_detail_assoc}_details".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ::AssetDetail,
          :manager_ref                  => %i(resource),
          :parent_inventory_collections => [asset_detail_assoc.to_s.pluralize.to_sym]
        )
      end
    end
  end

  def add_computer_systems
    %i(physical_server
       physical_chassis
       physical_storage).each do |computer_system_assoc|

      add_collection(physical_infra, "#{computer_system_assoc}_computer_systems".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ::ComputerSystem,
          :manager_ref                  => %i(managed_entity),
          :parent_inventory_collections => [computer_system_assoc.to_s.pluralize.to_sym]
        )
      end
    end
  end

  def add_computer_system_hardwares
    %i(physical_server
       physical_chassis
       physical_storage).each do |computer_system_assoc|

      add_collection(physical_infra, "#{computer_system_assoc}_hardwares".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ManageIQ::Providers::Lenovo::PhysicalInfraManager::Hardware,
          :manager_ref                  => %i(computer_system),
          :parent_inventory_collections => [computer_system_assoc.to_s.pluralize.to_sym]
        )
      end
    end
  end

  def add_physical_switch_hardwares
    add_collection(physical_infra, :physical_switch_hardwares) do |builder|
      builder.add_properties(
        :model_class                  => ManageIQ::Providers::Lenovo::PhysicalInfraManager::Hardware,
        :manager_ref                  => %i(physical_switch),
        :parent_inventory_collections => %i(physical_switches),
      )
    end
  end

  def add_physical_server_network_devices
    add_collection(physical_infra, :physical_server_network_devices) do |builder|
      builder.add_properties(
        :model_class                  => ::GuestDevice,
        :manager_ref                  => %i(device_type uid_ems),
        :parent_inventory_collections => %i(physical_servers)
      )
    end
  end

  def add_physical_server_storage_adapters
    add_collection(physical_infra, :physical_server_storage_adapters) do |builder|
      builder.add_properties(
        :model_class                  => ::GuestDevice,
        :manager_ref                  => %i(device_type uid_ems),
        :parent_inventory_collections => %i(physical_servers)
      )
    end
  end

  # Special :guest_device
  def add_management_devices
    %i(physical_server
       physical_chassis
       physical_storage).each do |management_device_assoc|

      add_collection(physical_infra, "#{management_device_assoc}_management_devices".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ::GuestDevice,
          :manager_ref                  => %i(device_type hardware),
          :parent_inventory_collections => [management_device_assoc.to_s.pluralize.to_sym]
        )
      end
    end
  end

  def add_management_device_networks
    %i(physical_server
       physical_chassis
       physical_storage).each do |network_assoc|

      add_collection(physical_infra, "#{network_assoc}_networks".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ::Network,
          :manager_ref                  => %i(guest_device ipaddress ipv6address),
          :manager_ref_allowed_nil      => %i(ipaddress ipv6address),
          :parent_inventory_collections => [network_assoc.to_s.pluralize.to_sym]
        )
      end
    end
  end

  def add_physical_switch_networks
    add_collection(physical_infra, :physical_switch_networks) do |builder|
      builder.add_properties(
        :model_class                  => ::Network,
        :manager_ref                  => %i(hardware ipaddress ipv6address),
        :manager_ref_allowed_nil      => %i(ipaddress ipv6address),
        :parent_inventory_collections => %i(physical_switches)
      )
    end
  end

  def add_firmwares
    %i(physical_server
       physical_storage
       physical_switch).each do |firmware_assoc|

      add_collection(physical_infra, "#{firmware_assoc}_firmwares".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ManageIQ::Providers::Lenovo::PhysicalInfraManager::Firmware,
          :manager_ref                  => %i(name resource),
          :parent_inventory_collections => [firmware_assoc.to_s.pluralize.to_sym]
        )
      end
    end

    # firmware for physical_server's guest_devices
    %i(network_device
       storage_adapter).each do |firmware_assoc|

      add_collection(physical_infra, "physical_server_#{firmware_assoc}_firmwares".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ManageIQ::Providers::Lenovo::PhysicalInfraManager::Firmware,
          :manager_ref                  => %i(name guest_device),
          :parent_inventory_collections => %i(physical_servers)
        )
      end
    end
  end

  def add_physical_network_ports
    %i(physical_server
       physical_storage
       physical_switch).each do |network_port_assoc|

      add_collection(physical_infra, "#{network_port_assoc}_network_ports".to_sym) do |builder|
        builder.add_properties(
          :model_class                  => ::PhysicalNetworkPort,
          :parent_inventory_collections => [network_port_assoc.to_s.pluralize.to_sym]
        )

        manager_ref = case network_port_assoc
                      when :physical_server then %i(port_type uid_ems)
                      when :physical_storage then %i(port_type port_name guest_device)
                      when :physical_switch then %i(port_type port_name physical_switch)
                      else []
                      end
        builder.add_properties(:manager_ref => manager_ref)
      end
    end
  end
end
