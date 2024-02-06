module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations
  extend ActiveSupport::Concern
  include ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender
  include ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::AnsibleSender

  def blink_loc_led(server, _options = {})
    change_led_state(server, :blink_loc_led)
  end

  def turn_on_loc_led(server, _options = {})
    change_led_state(server, :turn_on_loc_led)
  end

  def turn_off_loc_led(server, _options = {})
    change_led_state(server, :turn_off_loc_led)
  end

  def power_on(server, _options = {})
    change_resource_state(server, :power_on_node)
  end

  def power_off(server, _options = {})
    change_resource_state(server, :power_off_node)
  end

  def power_off_now(server, _options = {})
    change_resource_state(server, :power_off_node_now)
  end

  def restart(server, _options = {})
    change_resource_state(server, :power_restart_node)
  end

  def restart_now(server, _options = {})
    change_resource_state(server, :power_restart_node_now)
  end

  def restart_to_sys_setup(server, _options = {})
    change_resource_state(server, :power_restart_node_to_setup)
  end

  def restart_mgmt_controller(server, _options = {})
    change_resource_state(server, :power_restart_node_controller)
  end

  def apply_config_pattern(_args, options = {})
    $lenovo_log.info("Entering apply_config_pattern with pattern ID: #{options[:id]} and UUID: #{options[:uuid]}")

    # Retrieve a connection to the LXCA instance
    client = create_client_connection

    # Execute the action via the client
    response = client.send(:deploy_config_pattern, options[:id], [options[:uuid]], options[:restart], options[:etype])

    $lenovo_log.info("Exiting apply_config_pattern with pattern ID: #{options[:id]} and UUID: #{options[:uuid]}")

    response
  end

  private

  def create_client_connection
    auth = authentications.first
    endpoint = endpoints.first

    connect(:user => auth.userid,
            :pass => auth.password,
            :host => endpoint.hostname,
            :port => endpoint.port)
  end
end
