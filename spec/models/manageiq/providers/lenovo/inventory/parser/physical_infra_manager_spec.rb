describe ManageIQ::Providers::Lenovo::Inventory::Parser::PhysicalInfraManager do
  before(:all) do
    vcr_path = File.dirname(described_class.name.underscore)
    options = {:allow_playback_repeats => true}

    VCR.insert_cassette("#{vcr_path}/full_refresh", options)
  end

  after(:all) do
    while VCR.cassettes.last
      VCR.eject_cassette
    end
  end

  let(:auth) do
    FactoryBot.create(:authentication,
                      :userid   => Rails.application.secrets.lenovo[:username],
                      :password => Rails.application.secrets.lenovo[:password],
                      :authtype => "default")
  end

  let(:ems) do
    ems = FactoryBot.create(:physical_infra,
                            :name     => "LXCA",
                            :hostname => Rails.application.secrets.lenovo[:hostname],
                            :port     => "443")
    ems.authentications = [auth]
    ems
  end

  let(:parsed_data) do
    # Create and initialize the parser
    parser = described_class.new
    parser.collector = ManageIQ::Providers::Lenovo::Inventory::Collector::PhysicalInfraManager.new(ems, nil)
    parser.persister = ManageIQ::Providers::Lenovo::Inventory::Persister::PhysicalInfraManager.new(ems, nil)

    # Retrieve and parse the data and then return the parser which
    # will contain the parsed data
    parser.parse
    parser
  end

  context 'parse physical servers' do
    before do
      VCR.use_cassette("full_refresh") do
        result = parsed_data
        @physical_servers = result.components("physical_servers").persister.physical_servers.to_hash[:data]
      end
    end

    it 'will retrieve physical servers' do
      expect(@physical_servers.size).to eq(195)
    end

    it 'will retrieve physical network ports' do
      result = parsed_data
      network_ports = result.components("physical_network_ports").persister.physical_server_network_ports.to_hash[:data]

      # The associated guest device of this port has a UUID
      port1 = network_ports[102]
      expect(port1[:uid_ems]).to eq("C19BE1C07EE9429AB5860000C9E4FB421")
      expect(port1[:mac_address]).to eq("00:00:C9:E4:FB:42")

      # The associated guest device of this port does not have a UUID
      port2 = network_ports[4]
      expect(port2[:uid_ems]).to eq("5CF3FC6E3E48")
      expect(port2[:mac_address]).to eq("5C:F3:FC:6E:3E:48")
    end
  end
end
