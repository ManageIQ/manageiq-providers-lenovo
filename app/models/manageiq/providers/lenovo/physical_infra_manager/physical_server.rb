module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::PhysicalServer < ::PhysicalServer

    has_one :hardware

    def name
      "physical_server"
    end
  end
end
