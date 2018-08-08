#
# Has the Power Operation methods for Physical Chassis
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis::Operations
  extend ActiveSupport::Concern

  include_concern 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender'

  def blink_loc_led
    change_led_state(self, :blink_loc_led_chassis)
  end

  def turn_on_loc_led
    change_led_state(self, :turn_on_loc_led_chassis)
  end

  def turn_off_loc_led
    change_led_state(self, :turn_off_loc_led_chassis)
  end
end
