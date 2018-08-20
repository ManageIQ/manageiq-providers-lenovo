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

    let(:reponse) { subject.run_ansible(playbook_payload) }

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

    let(:reponse) { subject.run_ansible(playbook_payload) }

    let(:message) { 'Ansible::Runner#run_role' }

    before do
      allow(Ansible::Runner).to receive(:run_role) { message }
    end

    it 'should run Ansible::Runner#run_role' do
      expect(reponse).to eq(message)
    end
  end
end
