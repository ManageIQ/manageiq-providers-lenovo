require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  before :all do
    @auth = { :user => 'admin', :pass => 'smartvm', :host => 'localhost' }
  end

  it 'will execute discover successfully' do
    result = described_class.new.class.discover(@auth[:user], @auth[:pass], @auth[:host])
    expect(result).to eq([])
  end

  it 'will execute discover_queue successfully' do
    result = described_class.new.class.discover_queue(@auth[:user], @auth[:pass])
    expect(result).to_not eq(nil)
  end

  it 'will execute discover_from_queue successfully' do
    result = described_class.new.class.discover_from_queue(@auth[:user], @auth[:pass], @auth[:host])
    expect(result).to_not eq(nil)
  end

  it 'will execute verify_credentials successfully' do
    result = described_class.new.verify_credentials
    expect(result).to eq(true)
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
