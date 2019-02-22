describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations do
  let(:described_class_path) { described_class.name.underscore }
  let(:auth) do
    FactoryBot.create(:authentication,
                       :userid   => 'admin',
                       :password => 'password',
                       :authtype => 'default')
  end

  subject(:physical_infra_manager) do
    manager = FactoryBot.create(:physical_infra,
                                 :name      => 'LXCA',
                                 :hostname  => '10.243.9.123',
                                 :port      => '443',
                                 :ipaddress => 'https://10.243.9.123')
    manager.authentications = [auth]
    manager
  end

  describe 'location led' do
    let(:physical_server) do
      FactoryBot.create(:physical_server,
                         :name    => 'IMM2-e41f13ed5a1e',
                         :ems_ref => 'BD775D06821111E189A3E41F13ED5A1A')
    end

    it 'will turn on' do
      VCR.use_cassette("#{described_class_path}/turn_on_loc_led") do
        physical_infra_manager.turn_on_loc_led(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will turn off' do
      VCR.use_cassette("#{described_class_path}/turn_off_loc_led") do
        physical_infra_manager.turn_off_loc_led(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will blink' do
      VCR.use_cassette("#{described_class_path}/blink_loc_led") do
        physical_infra_manager.blink_loc_led(physical_server, :uuid => physical_server.ems_ref)
      end
    end
  end

  describe 'power operations' do
    let(:physical_server) do
      FactoryBot.create(:physical_server,
                         :name    => 'MimmNameDM',
                         :ems_ref => 'EADEBE8316174750A27FEC2E8226AC48')
    end

    it 'will power on a server' do
      VCR.use_cassette("#{described_class_path}/power_on") do
        physical_infra_manager.power_on(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will power off a server' do
      VCR.use_cassette("#{described_class_path}/power_off") do
        physical_infra_manager.power_off(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will immediately power off a server' do
      VCR.use_cassette("#{described_class_path}/power_off_now") do
        physical_infra_manager.power_off_now(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will restart a server' do
      VCR.use_cassette("#{described_class_path}/restart") do
        physical_infra_manager.restart(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will immediately restart a server' do
      VCR.use_cassette("#{described_class_path}/restart_now") do
        physical_infra_manager.restart_now(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will restart to system setup' do
      VCR.use_cassette("#{described_class_path}/restart_to_sys_setup") do
        physical_infra_manager.restart_to_sys_setup(physical_server, :uuid => physical_server.ems_ref)
      end
    end

    it 'will restart a server\'s management controller' do
      VCR.use_cassette("#{described_class_path}/restart_mgmt_controller") do
        physical_infra_manager.restart_mgmt_controller(physical_server, :uuid => physical_server.ems_ref)
      end
    end
  end

  describe 'apply configuration pattern' do
    let(:endpoint) { 'patterns' }
    let(:uuid)     { 'B918EDCA1B5F11E2803EBECB82710ADE' }
    let(:physical_infra_manager) do
      manager = FactoryBot.create(:physical_infra,
                                   :name     => 'LXCA',
                                   :hostname => 'sample.com',
                                   :port     => '443')
      manager.authentications = [auth]
      manager
    end

    context 'with valid id' do
      let(:pattern_id) { '1' }
      let(:response_body) do
        {
          :status => [200, 'OK'],
          :body   => JSON.generate('uuid' => [uuid], 'restart' => 'immediate')
        }
      end
      subject do
        physical_infra_manager.apply_config_pattern({}, { :id      => pattern_id,
                                                          :uuid    => uuid,
                                                          :etype   => 'node',
                                                          :restart => 'immediate'})
      end

      before do
        WebMock.allow_net_connect!
        stub_request(:post, "https://#{physical_infra_manager.hostname}/#{endpoint}/#{pattern_id}").to_return(response_body)
      end

      it 'should return response with status 200' do
        expect(subject.status).to eq(200)
      end

      it 'should have response body with correct data' do
        expect(JSON.parse(subject.body)).to include('uuid' => [uuid], 'restart' => 'immediate')
      end
    end

    context 'with invalid id' do
      let(:pattern_id) { '2' }
      let(:response_body) do
        {
          :status => [404, 'OK']
        }
      end
      subject do
        physical_infra_manager.apply_config_pattern({}, { :id      => pattern_id,
                                                          :uuid    => uuid,
                                                          :etype   => 'node',
                                                          :restart => 'immediate'})
      end

      before do
        WebMock.allow_net_connect!
        stub_request(:post, "https://#{physical_infra_manager.hostname}/#{endpoint}/#{pattern_id}").to_return(:status => [404, 'OK'])
      end

      it 'should return response with status 404' do
        expect(subject.status).to eq(404)
      end
    end
  end
end
