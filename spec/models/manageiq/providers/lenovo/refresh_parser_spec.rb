require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser do
  it 'will retrieve physical servers' do
    RefreshParser = ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser
    pim = FactoryGirl.create(:physical_infra_manager,
                             :name      => "LXCA",
                             :hostname  => "https://10.243.9.123",
                             :ipaddress => "https://10.243.9.123")
    auth = FactoryGirl.create(:authentication,
                              :userid   => 'admin',
                              :password => 'password',
                              :authtype => 'default')
    pim.authentications = [auth]
    rp = RefreshParser.new(pim)

    result = VCR.use_cassette("#{described_class.name.underscore}_ems_inv_to_hashes") do
      rp.ems_inv_to_hashes
    end

    expect(result[:physical_servers].size).to eq(4)
  end

  it 'will return its miq_template_type' do
    RefreshParser = ManageIQ::Providers::Lenovo::PhysicalInfraManager::RefreshParser
    expect(RefreshParser.miq_template_type).to eq("ManageIQ::Providers::Lenovo::PhysicalInfraManager::Template")
  end
end
