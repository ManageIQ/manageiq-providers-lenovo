describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch do
  context 'power operations' do
    let(:physical_switch) do
      physical_infra_manager = FactoryGirl.create(
        :physical_infra,
        :name      => 'LXCA',
        :hostname  => '10.243.9.123',
        :port      => '443',
        :ipaddress => 'https://10.243.9.123'
      )

      auth = FactoryGirl.create(
        :authentication,
        :userid   => 'admin',
        :password => 'password',
        :authtype => 'default'
      )

      physical_infra_manager.authentications = [auth]

      FactoryGirl.create(
        :lenovo_physical_switch,
        :name                  => 'Physical_Switch',
        :uid_ems               => '27997dba5dba11e89c2dfa7ae01bbebc',
        :ext_management_system => physical_infra_manager
      )
    end

    it 'should restart the physical switch' do
      VCR.use_cassette("#{described_class.name.underscore}_restart") do
        response = physical_switch.restart
        expect(response.status).to eq(200)
      end
    end
  end
end
