module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Provision::StateMachine
  def start_provisioning
    update_and_notify_parent(:message => msg('start provisioning'))
    signal :deploy_pxe_config
  end

  def deploy_pxe_config
    update_and_notify_parent(:message => msg('deploy pxe config'))
    source.deploy_pxe_config
    signal :reboot_using_pxe
  end

  def reboot_using_pxe
    update_and_notify_parent(:message => msg('reboot using PXE'))
    source.reboot_using_pxe
    signal :poll_server_running
  end

  def poll_server_running
    signal :done_provisioning
  end
end
