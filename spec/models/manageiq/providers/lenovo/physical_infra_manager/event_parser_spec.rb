require 'xclarity_client'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser do
  let(:event_attrs1) do
    {
      :msgID       => 1,
      :source      => 'LenovoXclarity',
      :msg         => 'This is a test event.',
      :timeStamp   => '2017-04-26T13:55:49.749552',
      :typeText    => 'Switch',
      :componentID => 'FFFFFFFFFFFFFFFFFFFFFFFF',
      :to_hash     => '',
      :ems_id      => 3,
    }
  end

  let(:event_attrs2) do
    {
      :msgID          => 1,
      :source         => 'LenovoXclarity',
      :sourceID       => 'AAAAAAAAAAAAAAAAAAAAAAA',
      :msg            => 'This is also a test event.',
      :timeStamp      => '2018-07-11T13:55:49.749552',
      :typeText       => 'Power',
      :systemTypeText => 'Chassis',
      :componentID    => '00FF00FF00FF00FF00FF00FF',
      :to_hash        => '',
      :ems_id         => 3,
    }
  end

  let(:physical_chassis) { FactoryBot.create(:physical_chassis, :uid_ems => 'AAAAAAAAAAAAAAAAAAAAAAA') }

  let(:event1) { XClarityClient::Event.new(event_attrs1) }
  let(:physical_switch) { FactoryBot.create(:physical_switch, :uid_ems => 'FFFFFFFFFFFFFFFFFFFFFFFF') }

  let(:event2) { XClarityClient::Event.new(event_attrs2) }
  let(:physical_server) { FactoryBot.create(:physical_server, :uid_ems => '00FF00FF00FF00FF00FF00FF') }

  context 'events are parsed' do
    it 'should belong to a switch' do
      physical_switch
      event_hash = described_class.event_to_hash(event1, 3)
      expect(event_hash[:event_type]).to eq(1)
      expect(event_hash[:source]).to eq('LenovoXclarity')
      expect(event_hash[:message]).to eq('This is a test event.')
      expect(event_hash[:timestamp]).to eq('2017-04-26T13:55:49.749552')
      expect(event_hash[:physical_server_id]).to be_nil
      expect(event_hash[:physical_switch_id]).to eq(physical_switch.id)
      expect(event_hash[:ems_id]).to eq(3)
    end

    it 'should belong to a server' do
      physical_server
      physical_chassis
      event_hash = described_class.event_to_hash(event2, 3)
      expect(event_hash[:event_type]).to eq(1)
      expect(event_hash[:source]).to eq('LenovoXclarity')
      expect(event_hash[:message]).to eq('This is also a test event.')
      expect(event_hash[:timestamp]).to eq('2018-07-11T13:55:49.749552')
      expect(event_hash[:physical_chassis_id]).to eq(physical_chassis.id)
      expect(event_hash[:physical_server_id]).to eq(physical_server.id)
      expect(event_hash[:physical_switch_id]).to be_nil
      expect(event_hash[:ems_id]).to eq(3)
    end
  end
end
