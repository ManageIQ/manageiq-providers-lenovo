FactoryGirl.define do
  factory :provider do
    sequence(:name) { |n| "provider_#{"013d"%n}" }
    guid            { MiqUUID.new_guid }
  end

  factory(:provider_lenovo, :class => "ManageIQ::Providers::Lenovo::Provider", :parent => :provider)do

	url "lenovo.example.com"

	after(:build) do |provider|
		provider.authentications << FactoryGirl.build(:authentication,
							      :userid	=> "admin"
							      :password => "lenovo"
	end
  end

end
