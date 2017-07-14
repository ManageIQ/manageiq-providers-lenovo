module ManageIQ::Providers::Lenovo::ManagerMixin
  extend ActiveSupport::Concern

  def description
    "Lenovo XClarity"
  end

  #
  # Connections
  #
  def connect(options = {})
    # raise "no credentials defined" if missing_credentials?(options[:auth_type])

    username   = options[:user] || authentication_userid(options[:auth_type])
    password   = options[:pass] || authentication_password(options[:auth_type])
    host       = options[:host]
    # TODO: improve this SSL verification
    verify_ssl = options[:verify_ssl] == 1 ? 'PEER' : 'NONE'
    self.class.raw_connect(username, password, host, verify_ssl)
  end

  def translate_exception(err)
  end

  def verify_credentials(_auth_type = nil, _options = {})
    # TODO: (julian) Find out if Lenovo supports a verify credentials method
    true
  end

  module ClassMethods
    #
    # Connections
    #
    def raw_connect(username, password, host, verify_ssl)
      require 'xclarity_client'
      xclarity = XClarityClient::Configuration.new(
        :username   => username,
        :password   => password,
        :host       => host,
        :verify_ssl => verify_ssl
      )
      XClarityClient::Client.new(xclarity)
    end

    #
    # Discovery
    #

    # Factory method to create EmsLenovo with instances
    #   or images for the given authentication.  Created EmsLenovo instances
    #   will automatically have EmsRefreshes queued up.
    def discover(ip_address, port)
      require 'xclarity_client'

      if XClarityClient::Discover.responds?(ip_address, port)
        new_ems = create!(
          :name     => "Discovered Provider ##{count + 1}",
          :hostname => URI('https://' + ip_address),
          :zone     => Zone.default_zone
        )

        # Set empty authentications
        create_default_authentications(new_ems)

        _log.info("Reached Lenovo XClarity Appliance with endpoint: #{ip_address}")
        _log.info("Created EMS: #{new_ems.name} with id: #{new_ems.id}")
      end

      EmsRefresh.queue_refresh(new_ems) unless new_ems.blank?
    end

    def discover_queue(username, password, zone = nil)
      MiqQueue.put(
        :class_name  => name,
        :method_name => "discover_from_queue",
        :args        => [username, MiqPassword.encrypt(password)],
        :zone        => zone
      )
    end

    private

    def discover_from_queue(username, password)
      discover(username, '')
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
