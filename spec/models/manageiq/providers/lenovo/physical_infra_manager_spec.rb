require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  before :all do
    @auth = { :user => 'admin', :pass => 'smartvm', :host => 'localhost' }
  end

  it 'will turn on a location LED successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "IMM2-e41f13ed5a1e",
                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]

    VCR.use_cassette("#{described_class.name.underscore}_turn_on_loc_led") do
      pim.turn_on_loc_led(ps, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
    end
  end

  it 'will turn off a location LED successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "IMM2-e41f13ed5a1e",
                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
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
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
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

  it 'power on a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "MimmNameDM",
                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
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
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
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

  it 'will restart a server successfully' do
    ps = FactoryGirl.create(:physical_server,
                            :name    => "MimmNameDM",
                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
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

  it 'will execute discover successfully' do
    result = described_class.new.class.discover(@auth[:user], @auth[:pass], @auth[:host])
    expect(result).to eq([])
  end

  it 'will execute discover_queue successfully' do
    result = described_class.new.class.discover_queue(@auth[:user], @auth[:pass])
    expect(result).to_not eq(nil)
  end

  it 'will execute discover_from_queue successfully' do
    result = described_class.new.class.discover_from_queue(@auth[:user], @auth[:pass], @auth[:host])
    expect(result).to_not eq(nil)
  end

  it 'will execute verify_credentials successfully' do
    result = described_class.new.verify_credentials
    expect(result).to eq(true)
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
end
