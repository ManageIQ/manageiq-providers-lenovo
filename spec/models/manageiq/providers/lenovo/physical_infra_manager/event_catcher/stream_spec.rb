describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream do
  let(:ems) do
    FactoryGirl.create(:physical_infra_with_authentication,
                       :name     => "LXCA",
                       :hostname => "https://10.243.9.123",
                       :port     => "443")
  end

  let(:stream) { described_class.new(ems) }

  it 'will start and stop without any exceptions occurring' do
    stream.start
    stream.stop
  end

  it 'will return the event monitor handle' do
    handle = stream.event_monitor_handle
    expect(handle).not_to eq(nil)
  end
end
