module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::ComputerSystem < Inventory::Parser::ComponentParser
    def build(parent)
      properties = {}
      add_parent(properties, parent)
      case parent[:object]&.base_class_name
      when "PhysicalServer" then @persister.physical_server_computer_systems.build(properties)
      when "PhysicalChassis" then @persister.physical_chassis_computer_systems.build(properties)
      when "Canister" then @persister.physical_storage_computer_systems.build(properties)
      else raise "Unknown association to computer_systems InventoryCollection"
      end
    end
  end
end
