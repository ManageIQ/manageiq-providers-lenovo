#TODO: Commented to extend PhysicalInfraManager directly from InfraManager
#class ManageIQ::Providers::PhysicalInfraManager < ManageIQ::Providers::InfraManager
#end

class ManageIQ::Providers::Lenovo::PhysicalInfraManager < ManageIQ::Providers::InfraManager
  include ManageIQ::Providers::Lenovo::ManagerMixin

  def description
    "Ué"
  end
end
