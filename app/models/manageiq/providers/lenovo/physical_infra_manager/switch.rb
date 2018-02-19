module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::Switch < ::Switch
    belongs_to :ext_management_system, :foreign_key => :ems_id, :inverse_of => :switches,
      :class_name => "ManageIQ::Providers::PhysicalInfraManager"
  end
end
