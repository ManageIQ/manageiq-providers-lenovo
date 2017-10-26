class ManageIQ::Providers::Lenovo::PhysicalInfraManager::ProvisionTask < MiqProvisionTask
  alias_attribute :physical_server, :source

  AUTOMATE_DRIVES = false
  SUCCESS = 200

  def description
    "Apply configuration pattern"
  end

  def self.request_class
    PhysicalServerProvisionRequest
  end

  def model_class
    ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer
  end

  def deliver_to_automate
    super("physical_server_provision", my_zone)
  end

  def do_request
    pattern_id = CustomizationScript.find_by(:id => options[:src_configuration_profile_id][0]).manager_ref
    response = physical_server.apply_config_pattern(pattern_id)

    if response.status == SUCCESS
      update_and_notify_parent(:state => "finished", :status => "Ok", :message => "#{request_class::TASK_DESCRIPTION} complete")
    else
      msg = JSON.parse(response.body)["message"]
      update_and_notify_parent(:state => "finished", :status => "Error", :message => "Error: #{msg}")
    end
  end
end
