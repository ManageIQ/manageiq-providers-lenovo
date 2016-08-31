module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::ComputeNode < ::ComputeNode
    def name
      "xclarity_compute_node"
    end
  end
end
