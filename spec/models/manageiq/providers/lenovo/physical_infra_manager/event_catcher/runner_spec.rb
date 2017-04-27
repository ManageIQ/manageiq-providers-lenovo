describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Runner do
  let(:ems) do
    FactoryGirl.create(:physical_infra_with_authentication,
                       :name      => "LXCA",
                       :hostname  => "https://10.243.9.123")
  end

  let(:runner) { described_class.new(:ems_id => ems.id) }

  before do
    allow_any_instance_of(ManageIQ::Providers::Lenovo::PhysicalInfraManager).to receive_messages(:authentication_check => [true, ""])
    allow_any_instance_of(MiqWorker::Runner).to receive(:worker_initialization)
  end

  it 'will stop the event monitor without any exceptions occurring' do
    runner.stop_event_monitor
  end
end
