module ManageIQ::Providers::Lenovo::ManagerMixin
  extend ActiveSupport::Concern

  def description
  end

  #
  # Connections
  #

  def connect(options = {})

    self.class.raw_connect()
  end

  def translate_exception(err)
  end

  def verify_credentials()
  end

  module ClassMethods
    #
    # Connections
    #

    def raw_connect()
    end

    #
    # Discovery
    #
    def discover()

    end
  end
end
