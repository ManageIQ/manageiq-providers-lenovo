describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::AuthenticatableProvider do
  let(:described_class_path) { described_class.name.underscore }
  let(:auth) do
    FactoryBot.create(:authentication,
                       :userid   => 'admin',
                       :password => 'password',
                       :authtype => 'default')
  end

  subject(:physical_infra_manager) do
    manager = FactoryBot.create(:physical_infra,
                                 :name      => 'LXCA',
                                 :hostname  => '10.243.9.123',
                                 :port      => '443',
                                 :ipaddress => 'https://10.243.9.123')
    manager.authentications = [auth]
    manager
  end

  describe 'change password' do
    context 'with invalid password' do
      it 'will not change password' do
        VCR.use_cassette("#{described_class_path}/change_password_with_invalid_password") do
          expect do
            physical_infra_manager.raw_change_password('invalid_pass', 'invalid_pass')
          end.to raise_error(MiqException::Error, 'The request to change the password for user ID CHG_PASS could not be completed because of an authentication issue.')
        end
      end
    end

    context 'with invalid new password' do
      it 'will not change password' do
        VCR.use_cassette("#{described_class_path}/change_password_with_invalid_new_password") do
          expect do
            physical_infra_manager.raw_change_password('invalid_pass', 'invalid')
          end.to raise_error(MiqException::Error, 'The request to change the password for user ID CHG_PASS could not be completed because of a password policy violation.')
        end
      end
    end

    context 'with valid new password' do
      it 'will change password' do
        VCR.use_cassette("#{described_class_path}/change_password_with_valid_password") do
          expect(physical_infra_manager.raw_change_password('password', 'valid@123')).to be_truthy
        end
      end
    end
  end
end
