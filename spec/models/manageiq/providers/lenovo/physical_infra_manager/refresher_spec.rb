describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Refresher do
  let(:auth) do
    FactoryGirl.create(:authentication,
                       :userid   => 'admin',
                       :password => 'password',
                       :authtype => 'default')
  end

  let(:ems) do
    FactoryGirl.create(:physical_infra,
                       :name      => "LXCA",
                       :hostname  => "https://10.243.9.123",
                       :port      => "443",
                       :ipaddress => "https://10.243.9.123:443").tap do |ems|
                         ems.authentications << auth
                       end
  end

  it 'will perform a full refresh' do
    2.times do # Run twice to verify that a second run with existing data does not change anything
      result = VCR.use_cassette("#{described_class.name.underscore}") do
        EmsRefresh.refresh(ems)
      end

      ems.reload

      assert_table_counts
    end
  end

  def assert_table_counts
    expect(PhysicalServer.count).to eq(3)
  end
end
