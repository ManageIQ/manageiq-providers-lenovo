require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do

  pending "Must test authentication verification"

  pending "Must test discovery"

  before :all do
    @auth = { user: 'admin', pass: 'smartvm', host: 'localhost', verify_ssl: 'true'}
  end

  it 'ems_type should be lenovo_physical_infra_manager' do
    expect(described_class.ems_type).to eq('lenovo_physical_infra_manager')
  end

  it 'description should be "Lenovo XClarity"' do
    expect(described_class.description).to eq("Lenovo XClarity")
  end
end
