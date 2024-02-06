#
# Has the Power Operation methods for Physical Switches
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch::Operations
  extend ActiveSupport::Concern
  include ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender
  include ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::ComponentAnsibleSender

  #
  # Restarts the physical switch.
  #   it does the `power_cycle_soft` operation.
  #
  def restart
    change_resource_state(self, :power_cycle_soft_switch)
  end
end
