describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  before(:all) do
    vcr_path = File.dirname(described_class.name.underscore)
    options = {:allow_playback_repeats => true}

    VCR.insert_cassette("#{vcr_path}/mock_aicc", options)
    VCR.insert_cassette("#{vcr_path}/mock_cabinet", options)
    VCR.insert_cassette("#{vcr_path}/mock_config_patterns", options)
    VCR.insert_cassette("#{vcr_path}/mock_switches", options)
    VCR.insert_cassette("#{vcr_path}/mock_compliance_policy", options)
    VCR.insert_cassette("#{vcr_path}/full_refresh", options)
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
                             :name      => 'LXCA',
                             :hostname  => '10.243.9.123',
                             :port      => '443',
                             :ipaddress => 'https://10.243.9.123:443')
    ems.authentications = [auth]
    ems
  end

  let(:ems2) do
    # Note: The hostname below cannot be an IP address because it will
    #       cause the full refresh test to fail when being executed
    #       on the Travis CI site.
    ems2 = FactoryGirl.create(:physical_infra,
                              :name      => 'LXCA2',
                              :hostname  => 'lxcahost',
                              :port      => '443',
                              :ipaddress => 'https://10.243.9.123:443')
    ems2.authentications = [auth]
    ems2
  end

  let(:targets) { [ems] }

  let(:refresher) { described_class.new(targets) }

  it 'will parse the legacy inventory' do
    result = refresher.parse_legacy_inventory(ems)

    expect(result[:physical_servers].size).to eq(3)
    expect(result[:physical_chassis].size).to eq(1)
    expect(result[:physical_racks].size).to eq(1)
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
      EmsRefresh.refresh(ems2)
      ems2.reload

      assert_table_counts
      assert_specific_rack
      assert_specific_server
      assert_guest_table_contents
      assert_physical_network_ports_table_content
    end
  end

  def assert_specific_rack
    rack = PhysicalRack.find_by(:ems_ref => '096F8C92-08D4-4A24-ABD8-FE56D482F8C4')

    expect(rack.name).to eq('cabinet71')
    expect(rack.ems_id).to be_truthy
  end

  def assert_specific_server
    server = PhysicalServer.find_by(:ems_ref => 'BD775D06821111E189A3E41F13ED5A1A')

    expect(server.name).to eq('IMM2-e41f13ed5a1e')
    expect(server.health_state).to eq('Valid')
    expect(server.power_state).to eq('On')
    expect(server.vendor).to eq('lenovo')
    expect(server.ems_id).to be_truthy
    expect(server.physical_rack_id).to be_truthy
  end

  def assert_table_counts
    expect(PhysicalRack.count).to eq(3)
    expect(PhysicalServer.count).to eq(2)
    expect(GuestDevice.count).to eq(4)
    expect(PhysicalNetworkPort.count).to eq(34)
  end

  def assert_guest_table_contents
    server = PhysicalServer.find_by(:ems_ref => '7936DD182C5311E3A8D6000AF7256738')
    nic = server.hardware.nics.first
    expect(nic.device_name).to eq('Broadcom 2-port 1GbE NIC Card for IBM')
  end

  def assert_physical_network_ports_table_content
    server = PhysicalServer.find_by(:ems_ref => '7936DD182C5311E3A8D6000AF7256738')
    ports = server.hardware.nics.first.physical_network_ports

    port1 = ports.find_by(:port_name => 'Physical Port 1')
    port2 = ports.find_by(:port_name => 'Physical Port 2')

    expect(port1.port_name).to eq('Physical Port 1')
    expect(port1.mac_address).to eq('00:0A:F7:25:67:38')
    expect(port2.port_name).to eq('Physical Port 2')
    expect(port2.mac_address).to eq('00:0A:F7:25:67:39')
  end
end
