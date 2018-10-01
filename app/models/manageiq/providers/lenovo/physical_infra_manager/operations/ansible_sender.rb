#
# Mixin to run ansible operations
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::AnsibleSender
  extend ActiveSupport::Concern

  #
  # Executes ansible resources inside +root_dir+
  #
  # @param args [Hash] - The args to run the ansible resource.
  # @option args [String] 'playbook_name' - The name of the playbook to be executed.
  #         If this param is filled a yaml file that matches with the specified name
  #         will be searched inside +playbooks_dir+.
  #         In cases where the playbook is not in +playbooks_dir+ root, please, specify
  #         the relative path to it.
  #         Example:
  #           run_ansible({'playbook_name' => 'config/firmware_update_all_dev'})
  #
  # @option args [String] 'role_name' - The name of the role to be executed.
  #        If this param is filled it will search the role inside +roles_dir+.
  #        Example:
  #           run_ansible({'role_name' => 'lenovo.lxca-inventory'})
  #
  # @option args [Hash] vars - The set of vars needed to execute the ansible resource
  #
  # @return Ansible::Runner::Response
  #
  # @see #root_dir
  # @see #playbooks_dir
  # @see #roles_dir
  #
  def run_ansible(args = {})
    playbook_name, role_name, vars = load_params(args)
    if playbook_name.present?
      Ansible::Runner.run(
        {},
        ansible_default_vars.merge(vars),
        playbooks_dir.join(playbook_name)
      )
    else
      Ansible::Runner.run_role(
        {},
        ansible_default_vars.merge(vars),
        role_name,
        :roles_path => roles_dir
      )
    end
  end

  #
  # The set of default vars to run playbooks.
  #
  # @return [Hash] containing the default vars to run playbooks
  #
  def ansible_default_vars
    auth = authentications.first

    {
      'lxca_user'     => auth.userid,
      'lxca_password' => auth.password,
      'lxca_url'      => "https://#{hostname}",
    }
  end

  private

  #
  # The root dir where ansible lives
  #
  def root_dir
    ManageIQ::Providers::Lenovo::Engine.root.join("content/ansible_runner")
  end

  #
  # The dir where ansible plabooks lives
  #
  def playbooks_dir
    root_dir.join("playbooks/")
  end

  #
  # The dir where ansible roles lives
  #
  def roles_dir
    root_dir.join("roles/")
  end

  #
  # Extracts the params from payload
  #
  # @param args [Hash] - contains the arguments to run ansible
  #
  # @return the params to run ansible
  #
  def load_params(args)
    return args['playbook_name'], args['role_name'], args['vars'] || {}
  end
end
