describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer do
  before do
    allow(subject).to receive(:with_provider_object).and_yield(system)
  end

  let(:system)     { double('SYSTEM', :EthernetInterfaces => double(:Members => macs)) }
  let(:macs)       { [] }
  let(:pxe_image)  { FactoryBot.create(:pxe_image, :pxe_server => pxe_server) }
  let(:pxe_server) { FactoryBot.create(:pxe_server) }
  let(:template)   { FactoryBot.create(:customization_template) }

  describe '#deploy_pxe_config' do
    context 'when without macs' do
      let(:macs) { [] }
      it 'has a valid subject' do
        expect(subject).to be_truthy
        subject.deploy_pxe_config(pxe_image, template)
      end
    end
  end
  
  describe 'reboot using pxe' do
    context 'good path' do
      let(:macs) { [] }
      it 'has a valid subject' do
        expect(subject).to be_truthy
        subject.reboot_using_pxe()
      end
    end
  end
  
  describe 'powered on now' do
    context 'good path' do
      let(:macs) { [] }
      it 'has a valid subject' do
        expect(subject).to be_truthy
        expect(subject.powered_on_now?).to be_truthy
      end
    end
  end
end
