describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser do
  let(:auth) do
    FactoryGirl.create(:authentication,
                       :userid   => "admin",
                       :password => "password",
                       :authtype => "default")
  end

  let(:ems) do
    ems = FactoryGirl.create(:physical_infra,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :port      => "443",
                             :ipaddress => "https://10.243.9.123/443")
    ems.authentications = [auth]
    ems
  end

  let(:refresh_parser) do
    VCR.use_cassette("#{described_class.name.underscore}_aicc") { described_class.new(ems) }
  end

  it 'will retrieve physical servers' do
    result = VCR.use_cassette("#{described_class.name.underscore}_ems_inv_to_hashes") do
      refresh_parser.ems_inv_to_hashes
    end

    expect(result[:physical_servers].size).to eq(4)
  end

  it 'will retrieve addin cards on the physical servers' do
    result = VCR.use_cassette("#{described_class.name.underscore}_retrieve_addin_cards") do
      refresh_parser.ems_inv_to_hashes
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
    expect(guest_device[:field_replaceable_unit]).to eq("90Y9373")
    expect(guest_device[:location]).to eq("Bay 7")

    expect(guest_device[:child_devices][0][:address]).to eq("00:0A:F7:25:67:38")
    expect(guest_device[:child_devices][0][:device_type]).to eq("physical_port")
    expect(guest_device[:child_devices][0][:device_name]).to eq("Physical Port 1")
  end

  it 'will return its miq_template_type' do
    expect(described_class.miq_template_type).to eq("ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template")
  end

  it 'will retrieve config patterns' do
    result = VCR.use_cassette("#{described_class.name.underscore}_retrieve_config_patterns") do
      refresh_parser.ems_inv_to_hashes
    end

    expect(result[:customization_scripts][0][:manager_ref]).to eq("65")
    expect(result[:customization_scripts][0][:name]).to eq("17dspncsvdm-config")
    expect(result[:customization_scripts][0][:in_use]).to eq(false)
    expect(result[:customization_scripts][1][:manager_ref]).to eq("54")
    expect(result[:customization_scripts][1][:name]).to eq("DaAn")
    expect(result[:customization_scripts][1][:in_use]).to eq(false)
  end

  context 'retrieve disk capacity from a physical server' do
    before do
      @result = VCR.use_cassette("#{described_class.name.underscore}_retrieve_physical_server_disk_capacity") do
        refresh_parser.ems_inv_to_hashes
      end
    end

    it 'will retrieve disk capacity from a physical server' do
      physical_server_with_disk = @result[:physical_servers][0]
      computer_system = physical_server_with_disk[:computer_system]
      hardware = computer_system[:hardware]

      expect(hardware[:disk_capacity]).to eq(3_000_614_658_000)
    end

    it 'will try to retrieve disk capacity from a physical server without RAID information' do
      physical_server = @result[:physical_servers][1]
      computer_system = physical_server[:computer_system]
      hardware = computer_system[:hardware]

      expect(hardware[:disk_capacity]).to eq(0)
    end
  end
end
