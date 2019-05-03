module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Provision::StateMachine
  def start_provisioning
    update_and_notify_parent(:message => msg('start provisioning'))
    signal :update_firmware
  end

  def update_firmware
    update_and_notify_parent(:message => msg('updating firmware'))
    source.update_firmware
    signal :update_configuration
  end

  def update_configuration
    update_and_notify_parent(:message => msg('updating configuration'))
    source.update_configuration
    signal :poll_server_running
  end

  def poll_server_running
    signal :done_provisioning
  end
end
