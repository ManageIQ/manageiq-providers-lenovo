describe ManageIQ::Providers::Lenovo::ManagerMixin do
  let(:auth) do
    {
      :user => 'admin',
      :pass => 'smartvm',
      :host => 'localhost',
      :port => '3000'
    }
  end

  let(:tested_class) do
    ManageIQ::Providers::Lenovo::PhysicalInfraManager
  end

  let(:physical_infra_manager) do
    FactoryBot.create(:physical_infra,
                       :name      => 'LXCA1',
                       :hostname  => '10.243.5.255',
                       :port      => '443',
                       :ipaddress => '10.243.5.255')
  end

  let(:console_uri) do
    URI::HTTPS.build(:host => physical_infra_manager.hostname,
                     :port => physical_infra_manager.port)
  end

  it 'will execute discover_queue successfully' do
    expect(tested_class.discover_queue(auth[:user], auth[:pass])).to_not eq(nil)
  end

  it 'will execute verify_credentials failed' do
    expect { tested_class.new.verify_credentials }.to raise_error(MiqException::MiqHostError)
  end

  it 'connect should return a XClarityClient::Client object' do
    expect(tested_class.new.connect(auth)).to be_a(XClarityClient::Client)
  end

  it 'should build the console URI' do
    expect(physical_infra_manager.console_url).to eq(console_uri)
  end

  it 'console should be supported' do
    expect(tested_class.new.supports?(:native_console)).to be_truthy
  end

  describe 'discover' do
    let(:port)            { Random.rand(10_000).to_s }
    let(:address)         { URI("https://10.10.10.10:#{port}/aicc") }
    let(:invalid_address) { URI("https://10.10.10.12:#{port}") }

    before :each do
      EvmSpecHelper.local_miq_server(:zone => Zone.seed)
      WebMock.allow_net_connect!
      stub_request(:get, address.to_s).to_return(:status => [200, 'OK'])
    end

    context 'valid discover' do
      it 'should create a new instance' do
        expect { tested_class.discover(address.host, port) }.to change { tested_class.count }.by 1
      end
    end

    context 'invalid discover' do
      it 'should not create a new instance' do
        expect { tested_class.discover(invalid_address.host, port) }.to change { tested_class.count }.by 0
      end
    end

    context 'from queue' do
      it 'should create a new instance' do
        expect { tested_class.send(:discover_from_queue, address.host, port) }.to change { tested_class.count }.by 1
      end
    end
  end

  describe 'exceptions handling' do
    context 'authentication error' do
      subject do
        tested_class.connection_rescue_block do
          raise XClarityClient::Error::AuthenticationError.new, 'Authentication error'
        end
      end

      it 'should raise MiqInvalidCredentialsError with correctly translated message' do
        expect { subject }.to raise_error(MiqException::MiqInvalidCredentialsError, 'Login failed due to a bad username or password.')
      end
    end

    context 'connection failed error' do
      subject do
        tested_class.connection_rescue_block do
          raise XClarityClient::Error::ConnectionFailed.new, 'Connection failed'
        end
      end

      it 'should raise MiqUnreachableError with correctly translated message' do
        expect { subject }.to raise_error(MiqException::MiqUnreachableError, 'Execution expired or invalid port.')
      end
    end

    context 'connection refused error' do
      subject do
        tested_class.connection_rescue_block do
          raise XClarityClient::Error::ConnectionRefused.new, 'Connection refused'
        end
      end

      it 'should raise MiqHostError with correctly translated message' do
        expect { subject }.to raise_error(MiqException::MiqHostError, 'Connection refused, invalid host.')
      end
    end

    context 'unknown hostname error' do
      subject do
        tested_class.connection_rescue_block do
          raise XClarityClient::Error::HostnameUnknown.new, 'Hostname unknown'
        end
      end

      it 'should raise MiqHostError with correctly translated message' do
        expect { subject }.to raise_error(MiqException::MiqHostError, 'Connection failed, unknown hostname.')
      end
    end

    context 'unknown errors' do
      subject do
        tested_class.connection_rescue_block do
          raise StandardError.new, 'Unexpected error'
        end
      end

      it 'should raise MiqHostError with correctly translated message' do
        expect { subject }.to raise_error(MiqException::MiqHostError, 'Unexpected response returned from system: unexpected error')
      end
    end
  end
end
