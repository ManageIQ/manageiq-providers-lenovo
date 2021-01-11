#
# Mixin to run ansible operations for physical components
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::ComponentAnsibleSender
  extend ActiveSupport::Concern

  include module_parent::AnsibleSender

  #
  # It adds some extra vars to run playbook against physical components
  #
  # @see AnsibleSender#ansible_default_vars
  #
  def ansible_default_vars
    ext_management_system.ansible_default_vars.merge(
      'endpoint' => try(:ems_ref) || try(:uid_ems)
    )
  end
end
