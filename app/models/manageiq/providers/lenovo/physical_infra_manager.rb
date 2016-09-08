class ManageIQ::Providers::PhysicalInfraManager < ManageIQ::Providers::InfraManager
end

class ManageIQ::Providers::Lenovo::PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
  include ManageIQ::Providers::Lenovo::ManagerMixin
end
