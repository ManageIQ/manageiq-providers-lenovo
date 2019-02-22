FactoryBot.define do
  factory :lenovo_physical_server, :class => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer, :parent => :physical_server do
  end
end
