describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  before(:all) do
    vcr_path = File.dirname(described_class.name.underscore)
    options = {:allow_playback_repeats => true}

    VCR.insert_cassette("#{vcr_path}/mock_aicc", options)
    VCR.insert_cassette("#{vcr_path}/mock_cabinet", options)
    VCR.insert_cassette("#{vcr_path}/mock_config_patterns", options)
  end
  after(:all) do
    while VCR.cassettes.last
      VCR.eject_cassette
    end
  end

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
    result = refresher.parse_legacy_inventory(ems)

    expect(result[:physical_servers].size).to eq(2)
  end

  it 'will save the inventory' do
    ems.authentications = [auth]

    refresher.save_inventory(ems, nil, {})
  end

  it 'will execute post_process_refresh_classes' do
    expect(refresher.post_process_refresh_classes).to eq([])
  end

  it 'will perform a full refresh' do
    # Perform the refresh twice to verify that a second run with existing data
    # does not change anything
    2.times do
      EmsRefresh.refresh(ems)
      ems.reload

      assert_table_counts
      assert_guest_table_contents
    end
  end

  def assert_table_counts
    expect(PhysicalServer.count).to eq(2)
    expect(GuestDevice.count).to eq(5)
  end

  def assert_guest_table_contents
    server = PhysicalServer.find_by(:ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    nic = server.hardware.nics.first
    ports = nic.child_devices
    port1 = ports.find_by(:device_name => "Physical Port 1")
    port2 = ports.find_by(:device_name => "Physical Port 2")

    expect(nic.device_name).to eq("Broadcom 2-port 1GbE NIC Card for IBM")
    expect(port1.device_name).to eq("Physical Port 1")
    expect(port1.address).to eq("00:0A:F7:25:67:38")
    expect(port2.device_name).to eq("Physical Port 2")
    expect(port2.address).to eq("00:0A:F7:25:67:39")
  end
end
