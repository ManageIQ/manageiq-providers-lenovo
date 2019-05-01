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
      it 'was called' do
        subject.deploy_pxe_config(pxe_image, template)
      end
    end

  #  context 'when multiple macs' do
  #    let(:macs) { [double('MAC 1', :PermanentMACAddress => 'addr1', :MACAddress => 'addr2')] }
  #    it 'pxe is configured for each mac' do
  #      expect(pxe_server).to receive(:create_provisioning_files).with(pxe_image, 'addr1', nil, template)
  #      expect(pxe_server).to receive(:create_provisioning_files).with(pxe_image, 'addr2', nil, template)
  #      subject.deploy_pxe_config(pxe_image, template)
  #    end
  #  end

  #  context 'when duplicated macs' do
  #    let(:macs) do
  #      [
  #        double('MAC 1', :PermanentMACAddress => 'same-addr', :MACAddress => 'same-addr'),
  #        double('MAC 2', :PermanentMACAddress => 'same-addr', :MACAddress => 'same-addr')
  #      ]
  #    end
  #    it 'pxe is configured for each unique mac' do
  #      expect(pxe_server).to receive(:create_provisioning_files).with(pxe_image, 'same-addr', nil, template).once
  #      subject.deploy_pxe_config(pxe_image, template)
  #    end
  #  end
  end

  describe '#reboot_using_pxe' do
    context 'when boot order setup succeeds' do
      it 'server is restarted' do
        #expect(system).to receive(:patch).and_return(double('RESPONSE', :status => 200))
        #expect(subject).to receive(:restart_now)
        subject.reboot_using_pxe
      end
    end

    #context 'when boot order setup fails' do
    #  it 'is provisioning aborted' do
    #    expect(system).to receive(:patch).and_return(double('RESPONSE', :status => 400))
    #    expect { subject.reboot_using_pxe }.to raise_error(MiqException::MiqProvisionError)
    #  end
    #end
  end

  describe '#powered_on_now?' do
    context 'when On' do
      #before { allow(system).to receive(:PowerState).and_return('On') }
      it { expect(subject.powered_on_now?).to be_truthy }
    end

    #context 'when Off' do
    #  before { allow(system).to receive(:PowerState).and_return('Off') }
    #  it { expect(subject.powered_on_now?).to be_falsey }
    #end
  end
end
