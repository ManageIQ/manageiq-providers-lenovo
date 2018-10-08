module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer::Operations
  extend ActiveSupport::Concern

  include_concern 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::ComponentAnsibleSender'

  #
  # Makes the provision of a server step-by-step using ansible methods.
  #   A Server provision consists in:
  #     - Update its firmwares;
  #     - Apply a config pattern
  #
  # @param config_pattern_id - the ID of the config pattern that will be used in
  #   provision.
  #
  # @return an array containing the response of all ansible executions.
  #
  def ansible_provision_server(config_pattern_id)
    responses = []
    responses << ansible_update_firmware
    responses << ansible_apply_pattern(config_pattern_id)

    responses
  end

  def ansible_update_firmware
    run_ansible(
      'role_name' => 'lenovo.lxca-config',
      'tags'      => 'update_all_firmware_withpolicy',
      'vars'      => {
        'mode'        => 'immediate',
        'uuid_list'   => uid_ems,
        'lxca_action' => 'apply'
      }
    )
  end

  def ansible_update_firmwares(firmware_names = [])
    run_ansible(
      'role_name' => 'lenovo.lxca-config',
      'tags'      => 'update_firmware',
      'vars'      => {
        'mode'        => 'immediate',
        'server'      => "#{uid_ems},#{firmware_names.join(',')}",
        'lxca_action' => 'apply'
      }
    )
  end

  def ansible_apply_pattern(pattern_id)
    run_ansible(
      'role_name' => 'lenovo.lxca-config',
      'tags'      => 'apply_configpatterns',
      'vars'      => {
        'endpoint' => uid_ems,
        'restart'  => 'immediate',
        'type'     => 'node',
        'id'       => pattern_id
      }
    )
  end
end
