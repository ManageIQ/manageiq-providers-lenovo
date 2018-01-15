require "xclarity_client"
require "faker"

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  before :all do
    @auth = { :user => "admin", :pass => "smartvm", :host => "localhost", :port => "3000" }
  end

  describe "location led" do
    before :each do
      @physical_server = FactoryGirl.create(:physical_server,
                                            :name    => "IMM2-e41f13ed5a1e",
                                            :ems_ref => "BD775D06821111E189A3E41F13ED5A1A")
      @physical_infra_manager = FactoryGirl.create(:physical_infra,
                                                   :name      => "LXCA",
                                                   :hostname  => "10.243.9.123",
                                                   :port      => "443",
                                                   :ipaddress => "https://10.243.9.123")
      @auth = FactoryGirl.create(:authentication,
                                 :userid   => "admin",
                                 :password => "password",
                                 :authtype => "default")
      @physical_infra_manager.authentications = [@auth]
    end

    it "will turn on a location LED successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_turn_on_loc_led") do
        @physical_infra_manager.turn_on_loc_led(@physical_server, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
      end
    end

    it "will turn off a location LED successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_turn_off_loc_led") do
        @physical_infra_manager.turn_off_loc_led(@physical_server, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
      end
    end

    it "will blink a location LED successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_blink_loc_led") do
        @physical_infra_manager.blink_loc_led(@physical_server, :uuid => "BD775D06821111E189A3E41F13ED5A1A")
      end
    end
  end

  describe "power operations" do
    before :each do
      @physical_server = FactoryGirl.create(:physical_server,
                                            :name    => "MimmNameDM",
                                            :ems_ref => "EADEBE8316174750A27FEC2E8226AC48")
      @physical_infra_manager = FactoryGirl.create(:physical_infra,
                                                   :name      => "LXCA",
                                                   :hostname  => "10.243.9.123",
                                                   :port      => "443",
                                                   :ipaddress => "https://10.243.9.123")
      @auth = FactoryGirl.create(:authentication,
                                 :userid   => "admin",
                                 :password => "password",
                                 :authtype => "default")
      @physical_infra_manager.authentications = [@auth]
    end

    it "will power on a server successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_power_on") do
        @physical_infra_manager.power_on(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will power off a server successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_power_off") do
        @physical_infra_manager.power_off(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will immediately power off a server successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_power_off_now") do
        @physical_infra_manager.power_off_now(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will restart a server successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_restart") do
        @physical_infra_manager.restart(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will immediately restart a server successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_restart_now") do
        @physical_infra_manager.restart_now(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will restart to system setup successfully" do
      VCR.use_cassette("#{described_class.name.underscore}_restart_to_sys_setup") do
        @physical_infra_manager.restart_to_sys_setup(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end

    it "will restart a server\'s management controller" do
      VCR.use_cassette("#{described_class.name.underscore}_restart_mgmt_controller") do
        @physical_infra_manager.restart_mgmt_controller(@physical_server, :uuid => @physical_server.ems_ref)
      end
    end
  end

  it "will execute discover_queue successfully" do
    result = described_class.new.class.discover_queue(@auth[:user], @auth[:pass])
    expect(result).to_not eq(nil)
  end

  it "will execute verify_credentials failed" do
    expect { described_class.new.verify_credentials }.to raise_error(MiqException::MiqHostError)
  end

  it "ems_type should be lenovo_ph_infra" do
    expect(described_class.ems_type).to eq("lenovo_ph_infra")
  end

  it "description should be 'Lenovo XClarity'" do
    expect(described_class.description).to eq("Lenovo XClarity")
  end

  it "connect should return a XClarityClient::Client object" do
    client = described_class.new.connect(@auth)
    expect(client).to be_a(XClarityClient::Client)
  end

  it "should build the console URI" do
    @physical_infra_manager = FactoryGirl.create(:physical_infra,
                                                 :name      => "LXCA1",
                                                 :hostname  => "10.243.5.255",
                                                 :port      => "443",
                                                 :ipaddress => "10.243.5.255")
    console_uri = URI::HTTPS.build(:host => @physical_infra_manager.hostname,
                                   :port => @physical_infra_manager.port)

    expect(@physical_infra_manager.console_url).to eq(console_uri)
  end

  it "console should be supported" do
    expect(described_class.new.console_supported?).to eql(true)
  end

  describe "discover" do
    context "valid discover" do
      before :each do
        EvmSpecHelper.local_miq_server(:zone => Zone.seed)
        @port = Random.rand(10_000).to_s
        @address = URI("https://" + Faker::Internet.ip_v4_address + ":" + @port)
        WebMock.allow_net_connect!
        stub_request(:get, File.join(@address.to_s, "/aicc")).to_return(:status => [200, "OK"])
      end

      it "should create a new instance" do
        expect { described_class.discover(@address.host, @port) }.to change { described_class.count }.by 1
      end
    end

    context "invalid discover" do
      before :each do
        @port = Random.rand(10_000).to_s
        @address = URI("https://" + Faker::Internet.ip_v4_address + ":" + @port)
      end
      it "should not create a new instance" do
        expect { described_class.discover(@address.host, @port) }.to change { described_class.count }.by 0
      end
    end

    context "from queue" do
      before do
        EvmSpecHelper.local_miq_server(:zone => Zone.seed)
        @port = Random.rand(10_000).to_s
        @address = URI("https://" + Faker::Internet.ip_v4_address + ":" + @port)
        WebMock.allow_net_connect!
        stub_request(:get, File.join(@address.to_s, "/aicc")).to_return(:status => [200, "OK"])
      end

      it "should create a new instance" do
        expect { described_class.send(:discover_from_queue, @address.host, @port) }.to change { described_class.count }.by 1
      end
    end
  end

  describe "exceptions handling" do
    context "authentication error" do
      subject do
        described_class.connection_rescue_block do
          raise XClarityClient::Error::AuthenticationError.new, "Authentication error"
        end
      end

      it "should raise MiqHostError with correctly translated message" do
        expect { subject }.to raise_error(MiqException::MiqHostError, "Login failed due to a bad username or password.")
      end
    end

    context "connection failed error" do
      subject do
        described_class.connection_rescue_block do
          raise XClarityClient::Error::ConnectionFailed.new, "Connection failed"
        end
      end

      it "should raise MiqHostError with correctly translated message" do
        expect { subject }.to raise_error(MiqException::MiqHostError, "Execution expired or invalid port.")
      end
    end

    context "connection refused error" do
      subject do
        described_class.connection_rescue_block do
          raise XClarityClient::Error::ConnectionRefused.new, "Connection refused"
        end
      end

      it "should raise MiqHostError with correctly translated message" do
        expect { subject }.to raise_error(MiqException::MiqHostError, "Connection refused, invalid host.")
      end
    end

    context "unknown hostname error" do
      subject do
        described_class.connection_rescue_block do
          raise XClarityClient::Error::HostnameUnknown.new, "Hostname unknown"
        end
      end

      it "should raise MiqHostError with correctly translated message" do
        expect { subject }.to raise_error(MiqException::MiqHostError, "Connection failed, unknown hostname.")
      end
    end

    context "unknown errors" do
      subject do
        described_class.connection_rescue_block do
          raise StandardError.new, "Unexpected error"
        end
      end

      it "should raise MiqHostError with correctly translated message" do
        expect { subject }.to raise_error(MiqException::MiqHostError, "Unexpected response returned from system: unexpected error")
      end
    end
  end

  describe "configuration pattern" do
    before :each do
      @physical_infra_manager = FactoryGirl.create(:physical_infra,
                                                   :name     => "LXCA",
                                                   :hostname => "sample.com",
                                                   :port     => "443")

      @auth = FactoryGirl.create(:authentication,
                                 :userid   => "admin",
                                 :password => "password",
                                 :authtype => "default")
      @physical_infra_manager.authentications = [@auth]

      @base_uri = "/patterns/"
      @uuid = "B918EDCA1B5F11E2803EBECB82710ADE"
    end

    context "with valid id" do
      before do
        @pattern_id = "1"
        response_body = {:status => [200, "OK"], :body => JSON.generate("uuid" => [@uuid], "restart" => "immediate")}
        WebMock.allow_net_connect!
        stub_request(:post, File.join("https://" + @physical_infra_manager.hostname, @base_uri + @pattern_id)).to_return(response_body)
      end

      subject do
        @physical_infra_manager.apply_config_pattern({}, {:id      => @pattern_id,
                                                          :uuid    => @uuid,
                                                          :etype   => "node",
                                                          :restart => "immediate"})
      end

      it "should return response with status 200" do
        expect(subject.status).to eq(200)
      end

      it "should have response body with correct data" do
        expect(JSON.parse(subject.body)).to include("uuid" => [@uuid], "restart" => "immediate")
      end
    end

    context "with invalid id" do
      before do
        @pattern_id = "2"

        WebMock.allow_net_connect!
        stub_request(:post, File.join("https://" + @physical_infra_manager.hostname, @base_uri + @pattern_id)).to_return(:status => [404, "OK"])
      end

      subject do
        @physical_infra_manager.apply_config_pattern({}, {:id      => @pattern_id,
                                                          :uuid    => @uuid,
                                                          :etype   => "node",
                                                          :restart => "immediate"})
      end

      it "should return response with status 404" do
        expect(subject.status).to eq(404)
      end
    end
  end
end
