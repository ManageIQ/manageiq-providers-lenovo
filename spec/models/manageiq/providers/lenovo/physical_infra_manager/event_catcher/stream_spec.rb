describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream do
  let(:ems) do
    FactoryGirl.create(:physical_infra_with_authentication,
                       :name     => "LXCA",
                       :hostname => "10.243.9.123",
                       :port     => "443")
  end

  let(:stream) { described_class.new(ems) }

  it 'will stop without any exceptions occurring' do
    stream.stop
  end
end
