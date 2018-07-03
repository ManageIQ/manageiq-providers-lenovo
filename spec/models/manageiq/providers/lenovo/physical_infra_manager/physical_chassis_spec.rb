describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis do
  describe 'power operations' do
    let(:physical_chassis) do
      physical_infra_manager = FactoryGirl.create(
        :physical_infra,
        :name      => "LXCA",
        :hostname  => "10.243.9.123",
        :port      => "443",
        :ipaddress => "https://10.243.9.123"
      )

      auth = FactoryGirl.create(
        :authentication,
        :userid   => "admin",
        :password => "password",
        :authtype => "default"
      )

      physical_infra_manager.authentications = [auth]

      FactoryGirl.create(
        :lenovo_physical_chassis,
        :name                  => "Physical_Chassis",
        :uid_ems               => "27997dba5dba11e89c2dfa7ae01bbebc",
        :ext_management_system => physical_infra_manager
      )
    end

    it 'will blink the location led' do
      VCR.use_cassette("#{described_class.name.underscore}_blink_loc_led") do
        response = physical_chassis.blink_loc_led
        expect(response.status).to eq(200)
      end
    end

    it 'will turn on the location led' do
      VCR.use_cassette("#{described_class.name.underscore}_turn_on_loc_led") do
        response = physical_chassis.turn_on_loc_led
        expect(response.status).to eq(200)
      end
    end

    it 'will turn off the location led' do
      VCR.use_cassette("#{described_class.name.underscore}_turn_off_loc_led") do
        response = physical_chassis.turn_off_loc_led
        expect(response.status).to eq(200)
      end
    end
  end
end
