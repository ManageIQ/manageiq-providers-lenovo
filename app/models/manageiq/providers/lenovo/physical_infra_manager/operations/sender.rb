module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::Sender
  extend ActiveSupport::Concern

  #
  # Sends the power operation to LXCA.
  #
  # @param [symbol] verb - the operation that must be sent
  #
  # @return the LXCA response
  #
  def change_resource_state(verb)
    $lenovo_log.info("The :#{verb} for #{self.class.name.demodulize} with uuid: #{uid_ems} is in progress")

    response = {}

    ext_management_system.with_provider_connection do |connection|
      response = connection.send(verb, uid_ems)
    end

    $lenovo_log.info("The :#{verb} for #{self.class.name.demodulize} with uuid: #{uid_ems} is completed")

    response
  end
end
