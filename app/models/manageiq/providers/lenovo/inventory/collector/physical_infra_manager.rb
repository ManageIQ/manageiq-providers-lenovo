class ManageIQ::Providers::Lenovo::Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Lenovo::Inventory::Collector
  # Returns all physical rack from the api.
  def physical_racks
    connection.discover_cabinet(:status => "includestandalone")
  end

  def physical_storages
    connection.discover_storages
  end

  # Returns physical servers that are inside a rack but not inside a chassis.
  def physical_servers_inside_rack(rack)
    rack.nodeList.map { |node| node["itemInventory"] }
  end

  # Returns physical chassis that are inside a rack.
  def physical_chassis_inside_rack(rack)
    rack.chassisList.map { |chassis| chassis["itemInventory"] }
  end

  # Returns physical servers that are inside a chassis.
  def physical_servers_inside_chassis(chassis)
    chassis["nodes"].reject { |node| node["type"] == "SCU" }
  end

  def physical_switches
    connection.discover_switches
  end

  def compliance_policies
    @compliance_policies ||= connection.fetch_compliance_policies
  end

  def config_patterns
    connection.discover_config_pattern
  end
end
