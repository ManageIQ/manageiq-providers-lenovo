#
# Has the Power Operation methods for Physical Switches
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch::Operations
  extend ActiveSupport::Concern

  #
  # Restarts the physical switch.
  #   it does the `power_cycle_soft` operation.
  #
  def restart
    change_resource_state(:power_cycle_soft_switch)
  end

  private

  #
  # Sends the power operation for a Switch.
  #
  # @param [symbol] verb - the operation that must be sent
  #
  # @return the LXCA response
  #
  def change_resource_state(verb)
    $lenovo_log.info("The :#{verb} for Physical Switch with uuid: #{uid_ems} is in progress")

    response = {}

    ext_management_system.with_provider_connection do |connection|
      response = connection.send(verb, uid_ems)
    end

    $lenovo_log.info("The :#{verb} for Physical Switch with uuid: #{uid_ems} is completed")

    response
  end
end
