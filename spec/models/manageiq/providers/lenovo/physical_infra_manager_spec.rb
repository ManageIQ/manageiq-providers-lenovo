describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  it 'ems_type should be lenovo_ph_infra' do
    expect(described_class.ems_type).to eq('lenovo_ph_infra')
  end

  it "description should be 'Lenovo XClarity'" do
    expect(described_class.description).to eq("Lenovo XClarity")
  end
end
