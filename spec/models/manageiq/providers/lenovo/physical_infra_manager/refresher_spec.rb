require_relative 'physical_infra_spec_common'
describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  include PhysicalInfraSpecCommon

  let(:physical_rack_ref) { "096F8C92-08D4-4A24-ABD8-FE56D482F8C4" }
  let(:physical_server_ref) do
    { :ems1 => "7936DD182C5311E3A8D6000AF7256738",
      :ems2 => "BD775D06821111E189A3E41F13ED5A1A" }
  end
  let(:physical_storage_ref) do
    { :ems1 => "208000C0FF2647DA",
      :ems2 => "123400C0FF261234" }
  end
  let(:physical_chassis_ref) do
    { :ems1 => "9841028B07714FD09D9297C6D1A4943E",
      :ems2 => nil }
  end
  let(:physical_switch_ref) { "00000000000010008000A48CDB984B00" }

  before(:all) do
    vcr_path = File.dirname(described_class.name.underscore)
    options = {:allow_playback_repeats => true}

    VCR.insert_cassette("#{vcr_path}/mock_aicc", options)
    VCR.insert_cassette("#{vcr_path}/mock_cabinet", options)
    VCR.insert_cassette("#{vcr_path}/mock_config_patterns", options)
    VCR.insert_cassette("#{vcr_path}/mock_storages", options)
    VCR.insert_cassette("#{vcr_path}/mock_switches", options)
    VCR.insert_cassette("#{vcr_path}/mock_compliance_policy", options)
    VCR.insert_cassette("#{vcr_path}/full_refresh", options)
  end
  after(:all) do
    while VCR.cassettes.last
      VCR.eject_cassette
    end
  end

  before(:each) do
    stub_settings_merge(
      :ems_refresh => {
        :lenovo_ph_infra => {
          :inventory_object_refresh => true,
          :inventory_collections    => {
            :saver_strategy => "default"
          }
        }
      }
    )
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

  let(:ems2) do
    # Note: The hostname below cannot be an IP address because it will
    #       cause the full refresh test to fail when being executed
    #       on the Travis CI site.
    ems2 = FactoryGirl.create(:physical_infra,
                              :name      => "LXCA2",
                              :hostname  => "lxcahost",
                              :port      => "443",
                              :ipaddress => "https://10.243.9.123:443")
    ems2.authentications = [auth]
    ems2
  end

  let(:targets) { [ems] }

  let(:refresher) { described_class.new(targets) }

  it 'will parse the legacy inventory' do
    result = refresher.parse_legacy_inventory(ems)

    expect(result[:physical_servers].size).to eq(3)
    expect(result[:physical_storages].size).to eq(3)
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

  it 'will perform a full refresh with ems1' do
    2.times do
      EmsRefresh.refresh(ems)
      ems.reload

      assert_table_counts(:ems1)

      assert_specific_rack(:ems1)
      assert_specific_server(:ems1)
      assert_specific_storage(:ems1)
      assert_specific_chassis(:ems1)
      assert_specific_switch(:ems1)
      assert_specific_script
    end
  end

  it 'will perform a full refresh with ems2' do
    # Perform the refresh twice to verify that a second run with existing data
    # does not change anything
    2.times do
      EmsRefresh.refresh(ems2)
      ems2.reload

      assert_table_counts(:ems2)
      assert_specific_rack(:ems2)
      assert_specific_server(:ems2)
      assert_specific_storage(:ems2)
      assert_specific_switch(:ems2)
      assert_guest_table_contents
      assert_physical_network_ports_table_content
      assert_physical_network_ports_connection
    end
  end

  def lenovo_model(model)
    name = model.class.to_s.split('::').last

    lenovo_klass = "ManageIQ::Providers::Lenovo::PhysicalInfraManager::#{name}".safe_constantize
    if lenovo_klass.present? && lenovo_klass.to_s.split('::').size > 1
      model.becomes(lenovo_klass)
    else
      model
    end
  end

  it 'will check inventory consistency' do
    EmsRefresh.refresh(ems2)
    ems2.reload
    inventory_before = serialize_inventory

    EmsRefresh.refresh(ems2)
    ems2.reload
    inventory_after = serialize_inventory

    assert_models_not_changed(inventory_before, inventory_after)
  end

  def assert_table_counts(manager = :ems1)
    if manager == :ems1
      expect(PhysicalRack.count).to eq(1)
      expect(PhysicalServer.count).to eq(3)
      expect(PhysicalStorage.count).to eq(3)
      expect(PhysicalChassis.count).to eq(1)
      expect(PhysicalSwitch.count).to eq(1)
      expect(AssetDetail.count).to eq(8)
      expect(PhysicalDisk.count).to eq(12)
      expect(Canister.count).to eq(6)
      expect(ComputerSystem.count).to eq(10)
      expect(Hardware.count).to eq(11)
      expect(GuestDevice.count).to eq(14)
      expect(Firmware.count).to eq(20)
      expect(Network.count).to eq(12)
      expect(PhysicalNetworkPort.count).to eq(60)
      expect(CustomizationScript.count).to eq(2)
    else
      expect(PhysicalRack.count).to eq(3)
      expect(PhysicalServer.count).to eq(2)
      expect(PhysicalStorage.count).to eq(2)
      expect(PhysicalChassis.count).to eq(0)
      expect(PhysicalSwitch.count).to eq(1)
      expect(AssetDetail.count).to eq(5)
      expect(PhysicalDisk.count).to eq(5)
      expect(Canister.count).to eq(4)
      expect(ComputerSystem.count).to eq(6)
      expect(GuestDevice.count).to eq(8)
      expect(Firmware.count).to eq(13)
      expect(Network.count).to eq(8)
      expect(PhysicalNetworkPort.count).to eq(50)
    end
  end

  def assert_specific_rack(manager = :ems1)
    rack = PhysicalRack.find_by(:ems_ref => physical_rack_ref)

    expect(rack).to have_attributes(:uid_ems => physical_rack_ref,
                                    :name    => 'cabinet71')

    if manager == :ems1
      expect(rack.physical_servers.count).to eq(2)
      expect(rack.physical_chassis.count).to eq(1)
      expect(rack.physical_storages.count).to eq(1)
    end
    expect(rack.ems_id).to be_truthy
  end

  def assert_specific_server(manager = :ems1)
    server = PhysicalServer.find_by(:ems_ref => physical_server_ref[manager])
    attrs = {
      :ems1 => {
        :health_state => "Valid",
        :hostname     => "IMM2-6cae8b4b4f15",
        :name         => "17dspncsvdm",
        :power_state  => "Off",
        :uid_ems      => physical_server_ref[manager],
        :type         => ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer.to_s,
        :vendor       => 'lenovo',
      },
      :ems2 => {
        :name         => "IMM2-e41f13ed5a1e",
        :health_state => "Valid",
        :power_state  => "On",
        :uid_ems      => physical_server_ref[manager],
        :vendor       => "lenovo",
      }
    }

    expect(server).to have_attributes(attrs[manager])
    expect(server.ems_id).to be_truthy
    expect(server.physical_rack_id).to be_truthy

    if manager == :ems1
      server = lenovo_model(server)
      expect(server.computer_system).to be_present
      expect(server.asset_detail).to be_present

      assert_specific_server_computer_system(server.computer_system)
      assert_specific_server_detail(server.asset_detail)
    end
  end

  def assert_specific_server_computer_system(computer_system)
    expect(computer_system.hardware).to be_present
    assert_specific_server_hardware(computer_system.hardware)
  end

  def assert_specific_server_hardware(hardware)
    hardware = lenovo_model(hardware)

    expect(hardware).to have_attributes(
      :disk_capacity   => 300_000_000_000,
      :memory_mb       => 16_384,
      :cpu_total_cores => 30
    )

    expect(hardware.firmwares.count).to eq(5)
    expect(hardware.nics.count).to eq(1)
    expect(hardware.storage_adapters.count).to eq(1)
    expect(hardware.management_devices.count).to eq(1)

    # binding.pry
    assert_specific_server_firmware(hardware.firmwares.find_by(:name => 'UEFI (Primary)'))
    assert_specific_server_network_device(hardware.nics.first)
    assert_specific_storage_adapter(hardware.storage_adapters.first)
    assert_specific_management_device(hardware.management_devices.first)
  end

  def assert_specific_server_firmware(firmware)
    expect(firmware).to have_attributes(
      :name         => 'UEFI (Primary)',
      :build        => 'A9E139GUS',
      :version      => '4.10',
      :release_date => Time.utc(2017, 2, 21)
    )
  end

  def assert_specific_server_network_device(network_device)
    expect(network_device).to have_attributes(
      :controller_type        => 'Hash',
      :device_name            => 'Broadcom 2-port 1GbE NIC Card for IBM',
      :device_type            => 'ethernet',
      :field_replaceable_unit => '90Y9373',
      :manufacturer           => 'IBM',
      :location               => 'Bay 7',
      :uid_ems                => '1450',
    )

    expect(network_device.firmwares.count).to eq(1)
    expect(network_device.physical_network_ports.count).to eq(2)

    assert_server_network_device_firmware(network_device.firmwares.first)
    assert_server_network_port(network_device.physical_network_ports.find_by(:uid_ems => '14501'))
  end

  def assert_server_network_device_firmware(firmware)
    expect(firmware).to have_attributes(
      :build        => '0',
      :name         => 'Broadcom 2-port 1GbE NIC Card for IBM',
      :release_date => nil,
      :version      => '17.4.4.2a',
    )
  end

  def assert_server_network_port(physical_network_port)
    expect(physical_network_port).to have_attributes(
      :uid_ems     => '14501',
      :port_name   => 'Physical Port 1',
      :port_type   => 'ETHERNET',
      :mac_address => '00:0A:F7:25:67:38',
      :port_index  => 1
    )
  end

  def assert_specific_storage_adapter(storage_adapter)
    expect(storage_adapter).to have_attributes(
      :device_name            => 'ServeRAID M5210',
      :device_type            => 'storage',
      :location               => 'Bay 12',
      :controller_type        => 'Hash',
      :uid_ems                => '70',
      :manufacturer           => 'IBM',
      :field_replaceable_unit => 'N/A'
    )
  end

  def assert_specific_management_device(management_device)
    expect(management_device).to have_attributes(
      :device_type => 'management',
      :address     => '6C:AE:8B:4B:4F:15,6C:AE:8B:4B:4F:16',
    )

    expect(management_device.network).to be_present
    assert_specific_physical_server_network(management_device.network)
  end

  def assert_specific_physical_server_network(network)
    expect(network).to have_attributes(
      :ipaddress   => '10.243.6.17',
      :ipv6address => 'fd55:faaf:e1ab:2021:6eae:8bff:fe4b:4f15, fe80:0:0:0:6eae:8bff:fe4b:4f15'
    )
  end

  def assert_specific_server_detail(asset_detail)
    expect(asset_detail).to have_attributes(
      :description            => 'Chassis',
      :product_name           => 'Lenovo System x3850 X6',
      :manufacturer           => 'IBM(CLCN)',
      :machine_type           => '6241',
      :model                  => 'AC1',
      :serial_number          => '23Y6458',
      :field_replaceable_unit => 'None',
      :part_number            => '00D0188',
      :location_led_ems_ref   => 'Identify',
      :location_led_state     => 'Off'
    )
  end

  def assert_specific_storage(manager = :ems1)
    storage = PhysicalStorage.find_by(:ems_ref => physical_storage_ref[manager])
    attrs = {
      :ems1 => {
        :name                 => 'S2200-Test',
        :uid_ems              => '208000C0FF2647DA',
        :ems_ref              => '208000C0FF2647DA',
        :access_state         => 'Online',
        :health_state         => 'Critical',
        :overall_health_state => 'Critical',
        :type                 => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalStorage',
        :drive_bays           => 12,
        :enclosures           => 1,
        :canister_slots       => 2
      },
      :ems2 => {
        :name                 => 'S8000-1',
        :uid_ems              => '123400C0FF261234',
        :ems_ref              => '123400C0FF261234',
        :access_state         => 'Online',
        :health_state         => 'Critical',
        :overall_health_state => 'Critical',
        :type                 => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalStorage',
        :drive_bays           => 12,
        :enclosures           => 1,
        :canister_slots       => 2
      },
    }

    expect(storage).to have_attributes(attrs[manager])

    if manager == :ems1
      expect(storage.physical_disks.count).to eq(4)
      expect(storage.canisters.count).to eq(2)
      expect(storage.asset_detail).to be_present

      assert_specific_physical_disk(manager, storage.physical_disks.find_by(:serial_number => '6XN43QX50000B349D4LY'))
      assert_specific_canister(manager, storage.canisters.first)
      assert_specific_storage_detail(storage.asset_detail)
    elsif manager == :ems2
      expect(storage.physical_disks.count).to eq(1)
      expect(storage.canisters.count).to eq(2)

      assert_specific_physical_disk(manager, storage.physical_disks.find_by(:ems_ref => "123400C0FF261234_0"))

      assert_specific_canister(manager, storage.canisters.find_by(:ems_ref => "_0"))
    end
  end

  def assert_specific_physical_disk(manager, physical_disk)
    if manager == :ems1
      expect(physical_disk).to have_attributes(
        :serial_number   => '6XN43QX50000B349D4LY',
        :model           => 'ST9300653SS',
        :vendor          => 'IBM-ESXS',
        :status          => 'Up',
        :location        => '0.22',
        :health_state    => 'OK',
        :controller_type => 'SAS',
        :disk_size       => '300.0GB'
      )
    else
      expect(physical_disk).to have_attributes(
        :serial_number => '20183QX50000B3492018',
        :model => 'Canister_Driver_Model',
        :vendor => 'Canister_Driver_Vendor',
        :status => 'Up',
        :location => '0.50',
        :health_state => 'OK',
        :controller_type => 'SAS',
        :disk_size => '300.0GB'
      )
  end

  def assert_specific_canister(manager, canister)
    if manager == :ems1
      expect(canister).to have_attributes(
        :serial_number                => '11S00WC050Y010DH57V0KH',
        :name                         => 'controller_a',
        :position                     => 'Top',
        :status                       => 'Operational',
        :health_state                 => 'Normal',
        :disk_bus_type                => 'SAS',
        :phy_isolation                => 'Enabled',
        :controller_redundancy_status => 'Operational but not redundant',
        :disks                        => 0,
        :system_cache_memory          => 6144,
        :power_state                  => 'On',
        :host_ports                   => '4',
        :hardware_version             => '5.2',
      )
      expect(canister.computer_system).to be_present

      assert_specific_storage_computer_system(canister.computer_system)
    else
      expect(canister).to have_attributes(
        :name                         => 'controller_a',
        :status                       => 'Operational',
        :controller_redundancy_status => 'Operational but not redundant',
        :ems_ref => '_0'
      )

      expect(canister.physical_disks.size).to eq(1)
    end
  end

  def assert_specific_storage_detail(asset_detail)
    expect(asset_detail).to have_attributes(
      :description      => 'RTP_S3200_1',
      :contact          => 'Bay Nguyen',
      :lowest_rack_unit => '0',
      :resource_type    => 'PhysicalStorage',
      :product_name     => 'S3200',
      :machine_type     => '6411',
      :model            => 'S3200',
      :serial_number    => '2683AF',
    )
  end

  def assert_specific_storage_computer_system(computer_system)
    expect(computer_system.hardware).to be_present

    assert_specific_storage_hardware(computer_system.hardware)
  end

  def assert_specific_storage_hardware(hardware)
    hardware = lenovo_model(hardware)

    # change 1 -> 0 by https://github.com/ManageIQ/manageiq-providers-lenovo/pull/244
    expect(hardware.firmwares.count).to eq(0)
    expect(hardware.management_devices.count).to eq(1)

    # assert_specific_storage_firmware(hardware.firmwares.first)
    assert_specific_storage_management_device(hardware.management_devices.first)
  end

  # # removed by https://github.com/ManageIQ/manageiq-providers-lenovo/pull/244
  #
  # def assert_specific_storage_firmware(firmware)
  #   expect(firmware).to have_attributes(:name => '-')
  # end

  def assert_specific_storage_management_device(management_device)
    expect(management_device).to have_attributes(
      :device_name => 'mgmtport_a',
      :device_type => 'management',
      :address     => '00:c0:ff:26:5e:de'
    )

    expect(management_device.network).to be_present
    expect(management_device.physical_network_ports.count).to eq(4)

    assert_specific_storage_network(management_device.network)
    assert_specific_storage_network_ports(management_device.physical_network_ports.find_by(:port_type => 'physical_port', :port_name => 'A3'))
  end

  def assert_specific_storage_network(network)
    expect(network).to have_attributes(
      :ipaddress   => '10.243.5.61',
      :subnet_mask => '255.255.240.0'
    )
  end

  def assert_specific_storage_network_ports(network_port)
    expect(network_port).to have_attributes(
      :port_name   => 'A3',
      :port_type   => 'physical_port',
      :port_status => 'Disconnected'
    )
  end

  def assert_specific_chassis(manager = :ems1)
    return unless manager == :ems1

    chassis = PhysicalChassis.find_by(:ems_ref => physical_chassis_ref[manager])
    attrs = {
      :ems1 => {
        :uid_ems                      => "9841028B07714FD09D9297C6D1A4943E",
        :ems_ref                      => "9841028B07714FD09D9297C6D1A4943E",
        :name                         => "SN#Y034BG16E02C",
        :vendor                       => "lenovo",
        :type                         => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis",
        :health_state                 => "Valid",
        :overall_health_state         => "Warning",
        :management_module_slot_count => 2,
        :switch_slot_count            => 4,
        :fan_slot_count               => 10,
        :blade_slot_count             => 14,
        :powersupply_slot_count       => 6,
      },
      :ems2 => {
      }
    }

    expect(chassis).to have_attributes(attrs[manager])
    expect(chassis.ems_id).to be_truthy
    expect(chassis.physical_rack_id).to be_truthy

    if manager == :ems1
      expect(chassis.physical_servers.count).to eq(1)
      expect(chassis.physical_storages.count).to eq(1)
      expect(chassis.computer_system).to be_present
      expect(chassis.asset_detail).to be_present

      assert_specific_chassis_computer_system(chassis.computer_system)
      assert_specific_chassis_detail(chassis.asset_detail)
    end
  end

  def assert_specific_chassis_computer_system(computer_system)
    expect(computer_system.hardware).to be_present

    assert_specific_chassis_hardware(computer_system.hardware)
  end

  def assert_specific_chassis_hardware(hardware)
    hardware = lenovo_model(hardware)

    expect(hardware.management_devices.count).to eq(1)

    assert_specific_chassis_management_device(hardware.management_devices.first)
  end

  def assert_specific_chassis_management_device(management_device)
    expect(management_device).to have_attributes(:device_type => 'management')
    expect(management_device.network).to be_present

    assert_specific_chassis_network(management_device.network)
  end

  def assert_specific_chassis_network(network)
    expect(network).to have_attributes(:ipaddress => '10.243.14.175')
  end

  def assert_specific_chassis_detail(asset_detail)
    expect(asset_detail).to have_attributes(
      :description          => 'Lenovo Flex System Chassis',
      :contact              => 'No Contact Configured',
      :location             => 'No Location Configured',
      :lowest_rack_unit     => '0',
      :resource_type        => 'PhysicalChassis',
      :product_name         => 'IBM Chassis Midplane',
      :manufacturer         => 'IBM',
      :machine_type         => '7893',
      :model                => '92X',
      :serial_number        => '100080A',
      :location_led_ems_ref => 'Location',
      :location_led_state   => 'Off',
    )
  end

  def assert_specific_switch(manager = :ems1)
    switch = PhysicalSwitch.find_by(:uid_ems => physical_switch_ref)
    attrs = {
      :name         => "ThinkAgile-VX-NE1032-SW03",
      :uid_ems      => "00000000000010008000A48CDB984B00",
      :switch_uuid  => "00000000000010008000A48CDB984B00",
      :type         => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch",
      :health_state => "Valid",
      :power_state  => "on",
    }

    expect(switch).to have_attributes(attrs)
    expect(switch.ems_id).to be_truthy

    if manager == :ems1
      expect(switch.physical_network_ports.count).to eq(32)
      expect(switch.hardware).to be_present
      expect(switch.asset_detail).to be_present

      assert_specific_switch_hardware(switch.hardware)
      assert_specific_switch_detail(switch.asset_detail)
    end
  end

  def assert_specific_switch_hardware(hardware)
    hardware = lenovo_model(hardware)

    expect(hardware.firmwares.count).to eq(3)
    expect(hardware.networks.count).to eq(2)

    assert_specific_switch_firmware(hardware.firmwares.find_by(:name => 'Uboot - N/A'))
    assert_specific_switch_network(hardware.networks.find_by(:ipaddress => '10.243.4.79'))
  end

  def assert_specific_switch_firmware(firmware)
    expect(firmware).to have_attributes(
      :name    => 'Uboot - N/A',
      :version => '10.4.2.0',
    )
  end

  def assert_specific_switch_network(network)
    expect(network).to have_attributes(
      :ipaddress       => '10.243.4.79',
      :subnet_mask     => '127.0.0.1',
      :default_gateway => '0.0.0.0'
    )
  end

  def assert_specific_switch_detail(asset_detail)
    expect(asset_detail).to have_attributes(
      :description   => "32*10 GbE SFP+",
      :product_name  => "Lenovo ThinkSystem NE1032 RackSwitch",
      :manufacturer  => "LNVO",
      :serial_number => "Y056DH79E046",
      :part_number   => "00YL949",
    )
  end

  def assert_specific_script
    customization_script = CustomizationScript.find_by(:manager_ref => '65')

    expect(customization_script.manager_id).to be_truthy

    expect(customization_script).to have_attributes(
      :name         => '17dspncsvdm-config',
      :manager_ref  => '65',
      :description  => "Copy of the 17dspncsvdm servers settings Pattern created from server: 17dspncsvdm\nLearned on: Sep 19, 2017 10:58:18 AM",
      :user_defined => true,
      :in_use       => false
    )
  end

  def assert_guest_table_contents
    server = PhysicalServer.find_by(:ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    nic = server.hardware.nics.first
    expect(nic.device_name).to eq("Broadcom 2-port 1GbE NIC Card for IBM")
  end

  def assert_physical_network_ports_table_content
    server = PhysicalServer.find_by(:ems_ref => "7936DD182C5311E3A8D6000AF7256738")
    ports = server.hardware.nics.first.physical_network_ports

    port1 = ports.find_by(:port_name => "Physical Port 1")
    port2 = ports.find_by(:port_name => "Physical Port 2")

    expect(port1.port_name).to eq("Physical Port 1")
    expect(port1.mac_address).to eq("00:0A:F7:25:67:38")
    expect(port2.port_name).to eq("Physical Port 2")
    expect(port2.mac_address).to eq("00:0A:F7:25:67:39")
  end

  def assert_physical_network_ports_connection
    port1 = PhysicalNetworkPort.find_by(:mac_address => "00:0A:F7:25:67:39")
    port2 = PhysicalNetworkPort.find_by(:peer_mac_address => "00:0A:F7:25:67:39")

    expect(port1.connected_port).to eq(port2)
    expect(port2.connected_port).to eq(port1)
  end
end
