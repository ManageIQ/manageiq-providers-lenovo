describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  let(:auth) do
    FactoryGirl.create(:authentication,
                       :userid   => 'admin',
                       :password => 'password',
                       :authtype => 'default')
  end

  let(:ems) do
    FactoryGirl.create(:physical_infra,
                       :name      => "LXCA",
                       :hostname  => "https://10.243.9.123",
                       :ipaddress => "https://10.243.9.123")
  end

  let(:targets) { [ems] }
  let(:refresher) { described_class.new(targets) }

  it 'will parse the legacy inventory' do
    ems.authentications = [auth]

    result = VCR.use_cassette("#{described_class.name.underscore}_parse_legacy_inventory") do
      refresher.parse_legacy_inventory(ems)
    end

    expect(result[:physical_servers].size).to eq(3)
  end

  it 'will save the inventory' do
    ems.authentications = [auth]

    refresher.save_inventory(ems, {}, {})
  end

  it 'will execute post_process_refresh_classes' do
    expect(refresher.post_process_refresh_classes).to eq([])
  end
end
