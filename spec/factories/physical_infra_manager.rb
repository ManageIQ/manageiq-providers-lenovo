FactoryBot.define do
  factory :physical_infra,
          :class => "ManageIQ::Providers::Lenovo::PhysicalInfraManager" do
  end

  factory :physical_infra_with_authentication,
          :parent => :physical_infra do
    after :create do |x|
      x.authentications << FactoryBot.create(:authentication)
    end
  end
end
