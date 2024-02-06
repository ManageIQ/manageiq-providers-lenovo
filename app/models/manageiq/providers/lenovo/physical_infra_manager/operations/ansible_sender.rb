#
# Mixin to run ansible operations
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::AnsibleSender
  extend ActiveSupport::Concern
  include NotificationMixin

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
  #           ansible_run({'playbook_name' => 'config/firmware_update_all_dev'})
  #
  # @option args [String] 'role_name' - The name of the role to be executed.
  #        If this param is filled it will search the role inside +roles_dir+.
  #        Example:
  #           ansible_run({'role_name' => 'lenovo.lxca-inventory'})
  #
  # @option args [Hash] vars - The set of vars needed to execute the ansible resource
  #
  # @option args [Hash] user_id - The ID of the user that triggered the action. It is needed
  #         to notify user when the ansible execution finish
  #
  # @return Ansible::Runner::Response
  #
  # @see #root_dir
  # @see #playbooks_dir
  # @see #roles_dir
  #
  def ansible_run(args = {})
    playbook_name, role_name, vars, tags = load_params(args)

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
        :tags       => tags,
        :roles_path => roles_dir
      )
    end
  end

  #
  # This method should be used for Ansible executions throught
  #   enqueued tasks. It will create a notification for users
  #   after Ansible execution.
  #
  # @param ansible_method [Symbol] name of the method that must be executed.
  # @param args [Array] list of arguments needed to execute the ansible method.
  # @param user_id [Number] the ID of user that triggered the task.
  #
  # @return the response of the ansible execution.
  #
  # @raise [Exception] when method_name doesn't starts with 'ansible_'
  #
  def task_ansible_run(ansible_method, args, user_id)
    if ansible_method.to_s.starts_with?('ansible_')
      response = send(ansible_method, args)

      notify_user(ansible_method, user_id)

      response
    else
      raise MiqException::Error, _("%{method_name} is not a valid name to an Ansible operation!") % {:method_name => ansible_method}
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
    return args['playbook_name'],
           args['role_name'],
           args['vars'] || {},
           args['tags'],
           args['user_id']
  end

  def notify_user(ansible_method, user_id)
    if user_id
      notify_task_finish(
        "#{ansible_method} executed for #{name}",
        user_id
      )
    end
  end
end
