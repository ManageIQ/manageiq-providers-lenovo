describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  let(:auth) do
    FactoryGirl.create(:authentication,
                       :userid   => 'lxcc',
                       :password => 'PASSW0rD',
                       :authtype => 'default')
  end

  let(:ems) do
    ems = FactoryGirl.create(:physical_infra,
                       :name      => "LXCA",
                       :hostname  => "10.243.9.123",
                       :port      => "443",
                       :ipaddress => "https://10.243.9.123:443")
    ems.authentications = [auth]
    ems
  end

  let(:targets) { [ems] }

  let(:refresher) { described_class.new(targets) }

  it 'will parse the legacy inventory' do
    result = VCR.use_cassette("#{described_class.name.underscore}_aicc") { refresher.parse_legacy_inventory(ems) }

    expect(result[:physical_servers].size).to eq(4)
  end

  it 'will save the inventory' do
    ems.authentications = [auth]

    refresher.save_inventory(ems, nil, {})
  end

  it 'will execute post_process_refresh_classes' do
    expect(refresher.post_process_refresh_classes).to eq([])
  end
end
