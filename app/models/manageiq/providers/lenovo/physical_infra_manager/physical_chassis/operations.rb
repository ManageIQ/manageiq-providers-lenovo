#
# Has the Power Operation methods for Physical Chassis
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis::Operations
  extend ActiveSupport::Concern

  include_concern 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender'

  def blink_loc_led
    change_resource_state(:blink_loc_led_chassis)
  end

  def turn_on_loc_led
    change_resource_state(:turn_on_loc_led_chassis)
  end

  def turn_off_loc_led
    change_resource_state(:turn_off_loc_led_chassis)
  end
end
