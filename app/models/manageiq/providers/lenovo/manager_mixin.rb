require 'xclarity_client'

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
    # raise "no credentials defined" if missing_credentials?(options[:auth_type])

    username   = options[:user] || authentication_userid(options[:auth_type])
    password   = options[:pass] || authentication_password(options[:auth_type])
    host       = options[:host] || address
    port       = options[:port] || self.port
    auth_type  = AUTH_TYPES[options[:auth_type]]
    user_agent_label = Vmdb::Appliance.USER_AGENT

    # TODO: improve this SSL verification
    verify_ssl = options[:verify_ssl] == 1 ? 'PEER' : 'NONE'
    self.class.raw_connect(username, password, host, port, auth_type, verify_ssl, user_agent_label)
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

  # Default behavior is disabled console support, enabling it here
  def console_supported?
    true
  end

  # Override base class method to provide a provider specific url
  def console_url
    URI::HTTPS.build(:host => hostname,
                     :port => port)
  end

  module ClassMethods
    def raw_connect(username, password, host, port, auth_type, verify_ssl, user_agent_label, validate = false)
      xclarity = XClarityClient::Configuration.new(
        :username         => username,
        :password         => password,
        :host             => host,
        :port             => port,
        :auth_type        => auth_type,
        :verify_ssl       => verify_ssl,
        :user_agent_label => user_agent_label,
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

      EmsRefresh.queue_refresh(new_ems) unless new_ems.blank?
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
