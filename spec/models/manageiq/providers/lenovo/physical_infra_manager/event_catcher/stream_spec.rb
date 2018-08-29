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

  context "#each_batch" do
    it "yields a valid event" do
      VCR.use_cassette(described_class.name.underscore.to_s) do
        result = []
        pool = 2
        stream.each_batch do |events|
          result.push(*events)
          pool -= 1
          if pool < 1
            stream.stop
            expect(events.count).to be == 1
          else
            expect(events.count).to be == 8
          end
        end
        expect(result.count).to be == 9
        expect(result.all? { |item| item[:full_data][:severity_id] == 300 }).to be true
      end
    end
  end
end
