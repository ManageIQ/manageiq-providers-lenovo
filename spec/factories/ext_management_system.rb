FactoryGirl.define do
  # factory :ext_management_system do
  #   sequence(:name)      { |n| "ems_#{seq_padded_for_sorting(n)}" }
  #   sequence(:hostname)  { |n| "ems_#{seq_padded_for_sorting(n)}" }
  #   sequence(:ipaddress) { |n| ip_from_seq(n) }
  #   guid                 { MiqUUID.new_guid }
  #   zone                 { Zone.first || FactoryGirl.create(:zone) }
  # end
  #
  # # Intermediate classes
  #
  # factory :ems_infra,
  #         :aliases => ["manageiq/providers/infra_manager"],
  #         :class   => "ManageIQ::Providers::InfraManager",
  #         :parent  => :ext_management_system do
  # end
  #
  # # Leaf classes for ems_infra
  #
  # factory :ems_vmware,
  #         :aliases => ["manageiq/providers/vmware/infra_manager"],
  #         :class   => "ManageIQ::Providers::Vmware::InfraManager",
  #         :parent  => :ems_infra do
  # end
  #
  # factory :ems_vmware_with_authentication,
  #         :parent => :ems_vmware do
  #   after(:create) do |x|
  #     x.authentications << FactoryGirl.create(:authentication)
  #   end
  # end
end
