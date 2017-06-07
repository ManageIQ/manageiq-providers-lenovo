describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser do
  it 'will retrieve physical servers' do
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]
    rp = described_class.new(pim)

    result = VCR.use_cassette("#{described_class.name.underscore}_ems_inv_to_hashes") do
      rp.ems_inv_to_hashes
    end

    expect(result[:physical_servers].size).to eq(4)
  end

  it 'will retrieve addin cards on the physical servers' do
    pim = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]
    rp = described_class.new(pim)

    result = VCR.use_cassette("#{described_class.name.underscore}_retrieve_addin_cards") do
      rp.ems_inv_to_hashes
    end

    physical_server = result[:physical_servers][0]
    computer_system = physical_server[:computer_system]
    hardware = computer_system[:hardware]
    guest_device = hardware[:guest_devices][0]

    expect(guest_device[:device_name]).to eq("Broadcom 2-port 1GbE NIC Card for IBM")
    expect(guest_device[:device_type]).to eq("ethernet")
    expect(guest_device[:firmwares][0][:name]).to eq("Primary 17.4.4.2a-Active")
    expect(guest_device[:firmwares][0][:version]).to eq("17.4.4.2a")
    expect(guest_device[:manufacturer]).to eq("IBM")
    expect(guest_device[:fru]).to eq("90Y9373")
    expect(guest_device[:location]).to eq("7")

    expect(guest_device[:guest_devices][0][:address]).to eq("00:0A:F7:25:67:38")
    expect(guest_device[:guest_devices][0][:device_type]).to eq("ethernet port")
    expect(guest_device[:guest_devices][0][:device_name]).to eq("Physical Port 1")
  end

  it 'will return its miq_template_type' do
    expect(described_class.miq_template_type).to eq("ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template")
  end
end
