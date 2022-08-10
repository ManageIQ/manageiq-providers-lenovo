# Delay load a fairly expensive library until first use.
autoload(:XClarityClient, 'xclarity_client')

module ManageIQ::Providers::Lenovo::ManagerMixin
  extend ActiveSupport::Concern

  AUTH_TYPES = {
    'default' => 'token',
    nil       => 'basic_auth'
  }.freeze

  def description
    "Lenovo XClarity"
  end

  def connect(options = {})
    username   = options[:user] || authentication_userid(options[:auth_type])
    password   = options[:pass] || authentication_password(options[:auth_type])
    host       = options[:host] || address
    port       = options[:port] || self.port
    auth_type  = AUTH_TYPES[options[:auth_type]]
    timeout    = options[:timeout]
    user_agent_label = Vmdb::Appliance.USER_AGENT
    # TODO: improve this SSL verification
    verify_ssl = options[:verify_ssl] == 1 ? 'PEER' : 'NONE'
    self.class.raw_connect(username, password, host, port, auth_type, verify_ssl, user_agent_label, :timeout => timeout)
  end

  def verify_credentials(auth_type = nil, options = {})
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(auth_type)
    options[:auth_type] = auth_type.nil? ? 'default' : auth_type.to_s

    self.class.connection_rescue_block do
      with_provider_connection(options) do |lxca|
        self.class.validate_connection(lxca)
      end
    end
    true
  end

  # Override base class method to provide a provider specific url
  def console_url
    URI::HTTPS.build(:host => hostname, :port => port)
  end

  module ClassMethods
    def params_for_create
      {
        :fields => [
          {
            :component => 'sub-form',
            :id        => 'endpoints-subform',
            :name      => 'endpoints-subform',
            :title     => _('Endpoints'),
            :fields    => [
              {
                :component              => 'validate-provider-credentials',
                :id                     => 'authentications.default.valid',
                :name                   => 'authentications.default.valid',
                :skipSubmit             => true,
                :isRequired             => true,
                :validationDependencies => %w[type],
                :fields                 => [
                  {
                    :component  => "text-field",
                    :id         => "endpoints.default.hostname",
                    :name       => "endpoints.default.hostname",
                    :label      => _("Hostname (or IPv4 or IPv6 address)"),
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    :component    => "text-field",
                    :id           => "endpoints.default.port",
                    :name         => "endpoints.default.port",
                    :label        => _("API Port"),
                    :type         => "number",
                    :initialValue => 443,
                    :isRequired   => true,
                    :validate     => [{:type => "required"}],
                  },
                  {
                    :component  => "text-field",
                    :id         => "authentications.default.userid",
                    :name       => "authentications.default.userid",
                    :label      => _("Username"),
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    :component  => "password-field",
                    :id         => "authentications.default.password",
                    :name       => "authentications.default.password",
                    :label      => _("Password"),
                    :type       => "password",
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                ]
              },
            ],
          },
        ]
      }.freeze
    end

    # Verify Credentials
    #
    # args: {
    #   "endpoints" => {
    #     "default" => {
    #       "hostname" => String,
    #       "port" => Integer,
    #     }
    #   "authentications" => {
    #     "default" => {
    #       "userid" => String,
    #       "password" => String,
    #     }
    #   }
    def verify_credentials(args)
      endpoint = args.dig("endpoints", "default")
      authentication = args.dig("authentications", "default")

      hostname, port = endpoint&.values_at("hostname", "port")
      userid, password = authentication&.values_at("userid", "password")

      password = ManageIQ::Password.try_decrypt(password)
      password ||= find(args["id"]).authentication_password(endpoint_name) if args["id"]

      !!raw_connect(userid, password, hostname, port, "token", false, Vmdb::Appliance.USER_AGENT, true)
    end

    def raw_connect(username, password, host, port, auth_type, verify_ssl, user_agent_label, validate = false, timeout: nil)
      xclarity = XClarityClient::Configuration.new(
        :username         => username,
        :password         => password,
        :host             => host,
        :port             => port,
        :auth_type        => auth_type,
        :verify_ssl       => verify_ssl,
        :user_agent_label => user_agent_label,
        :timeout          => timeout
      )
      connection = XClarityClient::Client.new(xclarity)

      connection_rescue_block { validate_connection(connection) } if validate

      connection
    end

    def validate_connection(connection)
      connection.validate_configuration
    end

    def connection_rescue_block
      yield
    rescue => err
      miq_exception = translate_exception(err)
      raise unless miq_exception

      _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
      raise miq_exception
    end

    def translate_exception(err)
      case err
      when XClarityClient::Error::AuthenticationError
        MiqException::MiqInvalidCredentialsError.new('Login failed due to a bad username or password.')
      when XClarityClient::Error::ConnectionFailed
        MiqException::MiqUnreachableError.new('Execution expired or invalid port.')
      when XClarityClient::Error::ConnectionRefused
        MiqException::MiqHostError.new('Connection refused, invalid host.')
      when XClarityClient::Error::HostnameUnknown
        MiqException::MiqHostError.new('Connection failed, unknown hostname.')
      else
        MiqException::MiqHostError.new("Unexpected response returned from system: #{err.message.downcase}")
      end
    end

    # Factory method to create EmsLenovo with instances
    #   or images for the given authentication.  Created EmsLenovo instances
    #   will automatically have EmsRefreshes queued up.
    def discover(ip_address, port)
      if XClarityClient::Discover.responds?(ip_address, port)
        new_ems = create!(
          :name     => "Discovered Provider ##{count + 1}",
          :hostname => URI(ip_address),
          :zone     => Zone.default_zone,
          :port     => port
        )

        # Set empty authentications
        create_default_authentications(new_ems)

        _log.info("Reached Lenovo XClarity Appliance with endpoint: #{ip_address}")
        _log.info("Created EMS: #{new_ems.name} with id: #{new_ems.id}")
      end

      EmsRefresh.queue_refresh(new_ems) if new_ems.present?
    end

    def discover_queue(ip_address, port, zone = nil)
      MiqQueue.put(
        :class_name  => name,
        :method_name => "discover_from_queue",
        :args        => [ip_address, port],
        :zone        => zone
      )
    end

    private

    def discover_from_queue(ip_address, port)
      discover(ip_address, port)
    end

    def create_default_authentications(ems)
      auth = Authentication.new
      auth.userid = ''
      auth.password = ''
      auth.resource_id = ems.id
      auth.save!
    end
  end
end
