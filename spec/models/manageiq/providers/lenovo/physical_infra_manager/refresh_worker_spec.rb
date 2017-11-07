describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshWorker do
  it "ems_class should be defined correctly" do
    expect(described_class.ems_class).to eq(ManageIQ::Providers::Lenovo::PhysicalInfraManager)
  end

  it "settings name should be defined correctly" do
    expect(described_class.settings_name).to eq(:ems_refresh_worker_lenovo_physical_infra)
  end
end
