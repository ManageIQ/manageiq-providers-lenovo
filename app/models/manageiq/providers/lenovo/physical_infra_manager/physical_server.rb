module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    def name
      "physical_server"
    end

    has_many :firmwares, :foreign_key => "ph_server_uuid", :primary_key => "uuid"
  end
end
