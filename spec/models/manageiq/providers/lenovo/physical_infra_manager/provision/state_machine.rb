describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Provision do
  before { EvmSpecHelper.create_guid_miq_server_zone }

  let(:auth) do
    FactoryBot.create(:authentication,:userid   => 'admin',:password => 'password',:authtype => 'default')
  end

  let(:physical_infra_manager) do
    manager = FactoryBot.create(:physical_infra,:name => 'LXCA',:hostname  => '10.243.9.123',:port      => '443', :ipaddress => 'https://10.243.9.123')
    manager.authentications = [auth]
    manager
  end
  
  let(:server)    { FactoryBot.create(:lenovo_physical_server,:ext_management_system=>physical_infra_manager,  :name    => 'IMM2-e41f13ed5a1e',
                                                                :ems_ref => 'BD775D06821111E189A3E41F13ED5A1A') }
  let(:request)   { FactoryBot.create(:physical_server_provision_request) }
  let(:pxe_image) { FactoryBot.create(:pxe_image) }
  let(:template)  { FactoryBot.create(:customization_template) }

  subject { described_class.new(:source => server, :miq_request => request) }

  describe 'run state machine' do
    before { subject.update_attribute(:options, options) }
    before { allow(subject).to receive(:requeue_phase) { 
      subject.send(subject.phase) } }
    before do
      allow(subject).to receive(:signal) do |method|
        puts method
        subject.phase = method
        subject.send(method)
      end
      physical_infra_manager.connect( { :host=>"10.243.9.123", :port =>443})
    end

  # context 'abort when missing pxe image' do
  #   let(:options) { { :pxe_image_id => 'missing' } }
  #   it do
  #     expect { subject.start_provisioning }.to
  #      raise_error(MiqException::MiqProvisionError)
  #    end
  #  end

  #  context 'abort when missing customization template' do
  #    let(:options) { { :configuration_profile_id => 'missing' } }
  #    it do
  #      expect { subject.start_provisioning }.to raise_error(MiqException::MiqProvisionError)
  #    end
  #  end

    context 'when all steps succeed' do
      let(:options) { { :pxe_image_id => pxe_image.id, :configuration_profile_id => template.id } }
      it do
        #subject.start_provisioning
        expect(server).to receive(:update_firmware)
        expect(server).to receive(:update_configuration)
        #expect(server).to receive(:powered_on_now?).and_return(true)

        #expect(subject).to receive(:deploy_pxe_config)
        #expect(subject).to receive(:start_provisioning)
        #expect(subject).to receive(:done_provisioning)
        #expect(subject).to receive(:reboot_using_pxe)
        subject.start_provisioning
        #expect(subject).to receive(:start_provisioning)
      end
    end

 #   context 'when all steps succeed after polling' do
 #     let(:options) { { :pxe_image_id => pxe_image.id, :configuration_profile_id => template.id } }
 #     it do
 #       expect(server).to receive(:deploy_pxe_config).with(pxe_image, template)
 #       expect(server).to receive(:reboot_using_pxe)
 #       expect(server).to receive(:powered_on_now?).and_return(false, false, true)
#
#        expect(subject).to receive(:done_provisioning)
#        subject.start_provisioning
#      end
#    end
  end
end

