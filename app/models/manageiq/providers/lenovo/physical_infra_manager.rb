class ManageIQ::Providers::PhysicalInfraManager < ManageIQ::Providers::InfraManager
end

#TODO Lenovo::PhysucalInfraManager have to extends ManageIQ::Providers::PhysicalInfraManager
class ManageIQ::Providers::Lenovo::PhysicalInfraManager < ManageIQ::Providers::InfraManager
  include ManageIQ::Providers::Lenovo::ManagerMixin
end
