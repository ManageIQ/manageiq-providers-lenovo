class ManageIQ::Providers::Lenovo::Inventory::Persister::PhysicalInfraManager < ManageIQ::Providers::Lenovo::Inventory::Persister
  include ManageIQ::Providers::Lenovo::Inventory::Persister::Definitions::PhysicalInfraCollections

  def initialize_inventory_collections
    initialize_physical_infra_inventory_collections
  end
end
