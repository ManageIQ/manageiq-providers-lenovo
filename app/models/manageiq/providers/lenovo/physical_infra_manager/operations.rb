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

  def restart(args, options = {})
    change_resource_state(:power_restart_node, args, options)
  end

  private

  def change_resource_state(verb, args, options = {})
    $lenovo_log.info("Entering change resource state for #{verb} and uuid: #{args.uuid} ")

    # Connect to the LXCA instance
    auth = authentications.first
    endpoint = endpoints.first
    client = connect(:user => auth.userid,
                     :pass => auth.password,
                     :host => endpoint.hostname)

    # Turn on the location LED using the xclarity_client API
    client.send(verb, options[:uuid])

    $lenovo_log.info("Exiting change resource state for #{verb} and uuid: #{args.uuid}")
  end
end
