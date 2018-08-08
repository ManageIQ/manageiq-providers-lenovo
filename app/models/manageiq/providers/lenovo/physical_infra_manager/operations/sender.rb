module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender
  extend ActiveSupport::Concern

  #
  # Sends the power operation to LXCA.
  #
  # @param [Object] component - component that will suffer the action
  # @param [symbol] verb      - the operation that must be sent
  #
  # @return the LXCA response
  #
  def change_resource_state(component, verb)
    prepare_to_send_operation(component, verb) { |connection| connection.send(verb, discover_uuid(component)) }
  end

  #
  # Sends the L.E.D. operation to LXCA.
  #   If the component has `location_led_ems_ref` setted, it is parsed to xclarity_client
  #   else the name is not sent, and the xclarity_client will use the default name.
  #
  # @param [Object] component - component that will suffer the action
  # @param [symbol] verb      - the operation that must be sent
  #
  # @return the LXCA response
  #
  def change_led_state(component, verb)
    prepare_to_send_operation(component, verb) do |connection|
      location_led_name = component.asset_detail&.location_led_ems_ref
      location_led_name.present? ? connection.send(verb, discover_uuid(component), location_led_name) : connection.send(verb, discover_uuid(component))
    end
  end

  private

  #
  # This is the template method to send operation requests
  #   through xclarity_client.
  #
  def prepare_to_send_operation(component, verb)
    $lenovo_log.info("The :#{verb} for #{component.class.name.demodulize} with uuid: #{discover_uuid(component)} is in progress")

    response = {}

    ext_management_system.with_provider_connection do |connection|
      response = yield(connection)
    end

    $lenovo_log.info("The :#{verb} for #{component.class.name.demodulize} with uuid: #{discover_uuid(component)} is completed")

    response
  end

  def discover_uuid(component)
    component.try(:ems_ref) || component.try(:uid_ems)
  end
end
