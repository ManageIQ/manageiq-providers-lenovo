describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream do
  let(:ems) do
    FactoryGirl.create(:physical_infra_with_authentication,
                       :name     => 'LXCA',
                       :hostname => '10.243.9.123',
                       :port     => '443')
  end

  let(:stream) { described_class.new(ems) }

  it 'will stop without any exceptions occurring' do
    stream.stop
  end

  context '#each_batch' do
    it 'yields a valid event' do
      VCR.use_cassette(described_class.name.underscore.to_s) do
        result = []
        pool = 2
        stream.each_batch do |events|
          result.push(*events)
          pool -= 1
          if pool < 1
            stream.stop
            expect(events.count).to be == 1
            expect($log).to receive(:info).with(/Stopping collect of LXCA events .../)
          else
            expect(events.count).to be == 20
          end
        end
        expect(result.count).to be == 21
        expect(result.all? { |item| item[:full_data][:severity_id] == 200 }).to be true
      end
    end
  end
end
