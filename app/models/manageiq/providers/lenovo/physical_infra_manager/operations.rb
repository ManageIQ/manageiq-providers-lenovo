module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations
  extend ActiveSupport::Concern

  def blink_loc_led(server, options = {})
    change_resource_state(:blink_loc_led, server, options)
  end

  def turn_on_loc_led(server, options = {})
    change_resource_state(:turn_on_loc_led, server, options)
  end

  def turn_off_loc_led(server, options = {})
    change_resource_state(:turn_off_loc_led, server, options)
  end

  def power_on(args, options = {})
    change_resource_state(:power_on_node, args, options)
  end

  def power_off(args, options = {})
    change_resource_state(:power_off_node, args, options)
  end

  def power_off_now(args, options = {})
    change_resource_state(:power_off_node_now, args, options)
  end

  def restart(args, options = {})
    change_resource_state(:power_restart_node, args, options)
  end

  def restart_now(args, options = {})
    change_resource_state(:power_restart_node_now, args, options)
  end

  def restart_to_sys_setup(args, options = {})
    change_resource_state(:power_restart_node_to_setup, args, options)
  end

  def restart_mgmt_controller(args, options = {})
    change_resource_state(:power_restart_node_controller, args, options)
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

  def change_resource_state(verb, args, _options = {})
    $lenovo_log.info("Entering change resource state for #{verb} and uuid: #{args.ems_ref} ")

    # Retrieve a connection to the LXCA instance
    client = create_client_connection

    # Execute the action via the client
    response = client.send(verb, args.ems_ref)

    $lenovo_log.info("Exiting change resource state for #{verb} and uuid: #{args.ems_ref}")

    response
  end

  def create_client_connection
    auth = authentications.first
    endpoint = endpoints.first

    connect(:user => auth.userid,
            :pass => auth.password,
            :host => endpoint.hostname,
            :port => endpoint.port)
  end
end
