describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::AnsibleSender do
  let(:auth) do
    FactoryGirl.create(:authentication,
                       :userid   => 'admin',
                       :password => 'password',
                       :authtype => 'default')
  end

  subject(:physical_infra_manager) do
    manager = FactoryGirl.create(:physical_infra,
                                 :name      => 'LXCA',
                                 :hostname  => '10.243.9.123',
                                 :port      => '443',
                                 :ipaddress => 'https://10.243.9.123')
    manager.authentications = [auth]
    manager
  end

  it 'should return the right default vars' do
    expect(subject.ansible_default_vars).to include(
      'lxca_user'     => subject.authentications.first.userid,
      'lxca_password' => subject.authentications.first.password,
      'lxca_url'      => "https://#{subject.hostname}",
    )
  end

  context 'when execute playbook' do
    let(:playbook_payload) do
      {
        'playbook_name' => 'name'
      }
    end

    let(:reponse) { subject.ansible_run(playbook_payload) }

    let(:message) { 'Ansible::Runner#run' }

    before do
      allow(Ansible::Runner).to receive(:run) { message }
    end

    it 'should run Ansible::Runner#run' do
      expect(reponse).to eq(message)
    end
  end

  context 'when execute role' do
    let(:playbook_payload) do
      {
        'role_name' => 'name'
      }
    end

    let(:reponse) { subject.ansible_run(playbook_payload) }

    let(:message) { 'Ansible::Runner#run_role' }

    before do
      allow(Ansible::Runner).to receive(:run_role) { message }
    end

    it 'should run Ansible::Runner#run_role' do
      expect(reponse).to eq(message)
    end
  end

  describe '#task_ansible_run' do
    let(:message) { 'AnsibleSender#ansible_run' }

    let(:user) do
      FactoryGirl.create(:user)
    end

    let(:args) do
      { 'playbook_name' => 'name' }
    end

    before do
      allow(subject).to receive(:notify_task_finish) do
        FactoryGirl.create(:notification, :initiator => user)
      end

      allow(subject).to receive(:ansible_run) { message }
    end

    context 'with a valid method' do
      it 'should create a notification' do
        subject.task_ansible_run(:ansible_run, args, user.id)

        expect(Notification.count).to eq(1)
      end
    end

    context 'with an invalid method' do
      it 'should rase an error' do
        expect do
          subject.task_ansible_run(:invalid_ansible_method, args, user.id)
        end.to raise_error(MiqException::Error)
      end
    end
  end
end
