require 'xclarity_client'
require 'faker'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  before :all do
    @auth = { :user => 'admin', :pass => 'smartvm', :host => 'localhost', :port => '3000' }
  end

  it 'will turn on a location LED successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "IMM2-e41f13ed5a1e",
                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default',)
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_turn_on_loc_led") do
      pim.turn_on_loc_led(ps, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
    end
  end

  it 'will turn off a location LED successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "IMM2-e41f13ed5a1e",
                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_turn_off_loc_led") do
      pim.turn_off_loc_led(ps, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
    end
  end

  it 'will blink a location LED successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "IMM2-e41f13ed5a1e",
                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_blink_loc_led") do
      pim.blink_loc_led(ps, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
    end
  end

  it 'will power on a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "MimmNameDM",
                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_power_on") do
      pim.power_on(ps, :uuid => "EADEBE8316174750A27FEC2E8226AC48")
    end
  end

  it 'will power off a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "MimmNameDM",
                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_power_off") do
      pim.power_off(ps, :uuid => "EADEBE8316174750A27FEC2E8226AC48")
    end
  end

  it 'will immediately power off a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "17dspncsvdm",
                            :ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_power_off_now") do
      pim.power_off_now(ps, :uuid => "7936DD182C5311E3A8D6000AF7256738")
    end
  end

  it 'will restart a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "MimmNameDM",
                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_restart") do
      pim.restart(ps, :uuid => "EADEBE8316174750A27FEC2E8226AC48")
    end
  end

  it 'will immediately restart a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "17dspncsvdm",
                            :ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_restart_now") do
      pim.restart_now(ps, :uuid => "7936DD182C5311E3A8D6000AF7256738")
    end
  end

  it 'will restart to system setup successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "17dspncsvdm",
                            :ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_restart_to_sys_setup") do
      pim.restart_to_sys_setup(ps, :uuid => "7936DD182C5311E3A8D6000AF7256738")
    end
  end

  it 'will restart a server\'s management controller' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "17dspncsvdm",
                            :ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_restart_mgmt_controller") do
      pim.restart_mgmt_controller(ps, :uuid => "7936DD182C5311E3A8D6000AF7256738")
    end
  end

  it 'will execute discover_queue successfully' do
    result = described_class.new.class.discover_queue(@auth[:user], @auth[:pass])
    expect(result).to_not eq(nil)
  end

  it 'will execute verify_credentials failed' do
    expect { described_class.new.verify_credentials }.to raise_error(MiqException::MiqHostError)
  end

  it 'ems_type should be lenovo_ph_infra' do
    expect(described_class.ems_type).to eq('lenovo_ph_infra')
  end

  it 'description should be "Lenovo XClarity"' do
    expect(described_class.description).to eq("Lenovo XClarity")
  end

  it 'connect should return a XClarityClient::Client object' do
    client = described_class.new.connect(@auth)
    expect(client).to be_a(XClarityClient::Client)
  end

  it 'should support the remote console' do
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.240.5.555",
                             :port      => "443",
                             :ipaddress => "https://10.240.5.555")
    expect(pim.supports_console?).to be(true)
  end

  it 'should build the console URI' do
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "10.240.5.555",
                             :port      => "443",
                             :ipaddress => "10.243.5.555")
    console_uri = URI::HTTPS.build(:host => pim.hostname,
                                   :port => pim.port)

    expect(pim.supports_console?).to be(true)
    expect(pim.console_url).to eq(console_uri)
  end

  context 'valid discover' do
    before :each do
      EvmSpecHelper.local_miq_server(:zone => Zone.seed)
      @port = Random.rand(10_000).to_s
      @address = URI('https://' + Faker::Internet.ip_v4_address + ':' + @port)
      WebMock.allow_net_connect!
      stub_request(:get, File.join(@address.to_s, '/aicc')).to_return(:status => [200, 'OK'])
    end

    it 'should create a new instance' do
      expect { described_class.discover(@address.host, @port) }.to change { described_class.count }.by 1
    end
  end

  context 'invalid discover' do
    before :each do
      @port = Random.rand(10_000).to_s
      @address = URI('https://' + Faker::Internet.ip_v4_address + ':' + @port)
    end
    it 'should not create a new instance' do
      expect { described_class.discover(@address.host, @port) }.to change { described_class.count }.by 0
    end
  end
end
