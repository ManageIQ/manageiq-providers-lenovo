require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do

  pending "Must test authentication verification"

  pending "Must test discovery"

  before :all do
    @auth = { user: 'admin', pass: 'smartvm', host: 'localhost' }
  end

  it 'ems_type should be lenovo_ph_infra' do
    expect(described_class.ems_type).to eq('lenovo_ph_infra')
  end

  it 'description should be "Lenovo XClarity"' do
    expect(described_class.description).to eq("Lenovo XClarity")
  end

  it 'connect should return a XClarityClient::Client object' do
    client = described_class.new.connect(@auth)
    expect(client).to be_a(XClarityClient::Client)
  end
end
