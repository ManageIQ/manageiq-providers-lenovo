require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser do
  let(:event_attrs1) do
    {
      :eventID            => 1,
      :source             => "LenovoXclarity",
      :msg                => "This is a test event.",
      :timeStamp          => "2017-04-26T13:55:49.749552",
      :physical_server_id => "",
      :to_hash            => "",
      :ems_id             => 3
    }
  end

  let(:event1) { XClarityClient::Event.new(event_attrs1) }

  it 'will parse events' do
    event_hash = described_class.event_to_hash(event1, 3)
    expect(event_hash[:event_type]).to eq(1)
    expect(event_hash[:source]).to eq("LenovoXclarity")
    expect(event_hash[:message]).to eq("This is a test event.")
    expect(event_hash[:timestamp]).to eq("2017-04-26T13:55:49.749552")
    expect(event_hash[:ems_id]).to eq(3)
  end
end
