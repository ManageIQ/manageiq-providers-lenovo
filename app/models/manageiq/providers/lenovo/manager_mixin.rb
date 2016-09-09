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

    username = options[:user] || authentication_userid(options[:auth_type])
    password = options[:pass] || authentication_password(options[:auth_type])
    host     = options[:host]

    self.class.raw_connect(username, password, host)
  end

  def translate_exception(err)
  end

  def verify_credentials(auth_type = nil, options = {})
    # TODO: (julian) Find out if Lenovo supports a verify credentials method
    true
  end

  module ClassMethods
    #
    # Connections
    #
    def raw_connect(username, password, host)
      require 'xclarity_client'
      xclarity = XClarityClient::Configuration.new(
        :username => username,
        :password => password,
        :host     => host
      )
      XClarityClient::Client.new(xclarity)
    end

    #
    # Discovery
    #

    # Factory method to create EmsLenovo with instances
    #   or images for the given authentication.  Created EmsLenovo instances
    #   will automatically have EmsRefreshes queued up.
    def discover(username, password, host)
      new_emses         = []
      all_emses         = includes(:authentications)
      all_ems_names     = all_emses.map(&:name).to_set

      xclarity = raw_connect(username, password, host)

      EmsRefresh.queue_refresh(new_emses) unless new_emses.blank?

      new_emses
    end

    def discover_queue(username, password)
      MiqQueue.put(
        :class_name  => name,
        :method_name => "discover_from_queue",
        :args        => [username, MiqPassword.encrypt(password)]
      )
    end

    private

    def discover_from_queue(username, password)
      discover(access_key_id, MiqPassword.decrypt(secret_access_key))
    end
  end
end
