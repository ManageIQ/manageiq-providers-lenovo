module ManageIQ::Providers::Lenovo::ManagerMixin
  extend ActiveSupport::Concern

  def description
  end

  #
  # Connections
  #
  def connect(options = {})
    raise "no credentials defined" if missing_credentials?(options[:auth_type])

    username = options[:user] || authentication_userid(options[:auth_type])
    password = options[:pass] || authentication_password(options[:auth_type])
    host     = options[:host]

    self.class.raw_connect(username, password, host)
  end

  def translate_exception(err)
  end

  def verify_credentials()
  end

  module ClassMethods
    #
    # Connections
    #
    def raw_connect(username, password, host)
      require 'xclarity_client'
      XClarityClient::Configuration.new(
        :username => username,
        :password => password,
        :host     => host
      )
    end

    #
    # Discovery
    #
    def discover()

    end
  end
end
