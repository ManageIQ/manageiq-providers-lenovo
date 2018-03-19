module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'RemoteConsole'

    delegate :product_name,
             :product_name=,
             :manufacturer,
             :manufacturer=,
             :machine_type,
             :machine_type=,
             :model,
             :model=,
             :serial_number,
             :serial_number=,
             :field_replaceable_unit,
             :field_replaceable_unit=,
             :to        => :asset_detail,
             :allow_nil => true
  end
end
