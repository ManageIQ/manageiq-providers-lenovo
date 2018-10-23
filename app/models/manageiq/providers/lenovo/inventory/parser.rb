class ManageIQ::Providers::Lenovo::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  require_nested :PhysicalInfraManager

  VENDOR_LENOVO = "lenovo".freeze
end
