module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    def name
      "physical_server"
    end

    belongs_to :ext_management_system, :foreign_key => "ems_id", :class_name => "ManageIQ::Providers::Lenovo::PhysicalInfraManager"
    has_one :host, :foreign_key => "service_tag", :primary_key => "serial_number"
  end
end
