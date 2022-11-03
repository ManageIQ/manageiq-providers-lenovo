module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer::RemoteConsole
  extend ActiveSupport::Concern

  included do
    supports :console
  end

  def remote_console_acquire_resource(_userid, _originating_server)
    $lenovo_log.info("Entering remote_console_acquire_resource for server with id #{id}")

    # Retrieve a connection to the LXCA instance
    client = create_client_connection

    # Request remote console resource (jnlp file or url) via the client
    response = client.remote_control(ems_ref)

    $lenovo_log.info("Exiting remote_console_acquire_resource for server with id #{id}")

    response
  end

  private

  def create_client_connection
    ext_mgmt_system = ext_management_system
    auth = ext_mgmt_system.authentications.first
    endpoint = ext_mgmt_system.endpoints.first

    ext_mgmt_system.connect(:user => auth.userid,
                            :pass => auth.password,
                            :host => endpoint.hostname,
                            :port => endpoint.port)
  end
end
