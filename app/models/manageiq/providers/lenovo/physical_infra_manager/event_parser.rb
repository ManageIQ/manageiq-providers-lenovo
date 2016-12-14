module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(event, ems_id)
    #TODO: Here is where the event become a hash

    # log_header = "ems_id: [#{ems_id}] " unless ems_id.nil?
    #
    # _log.debug("#{log_header}event: [#{event["configurationItem"]["resourceType"]} - " \
    #            "#{event["configurationItem"]["resourceId"]}]")

    #TODO: Here's where we'll turn event in a hash
    event_hash = {
      :event_type => event.eventID,
      :source     => "LXCA",
      :message    => event.msg,
      :timestamp  => event.timeStamp,
#      :full_data  => event,
      :ems_id     => ems_id
    }

    # event_hash[:vm_ems_ref]                = parse_vm_ref(event)
    # event_hash[:availability_zone_ems_ref] = parse_availability_zone_ref(event)
    event_hash
  end

  def self.parse_vm_ref(event)
    #TODO: Investigating what this function do.
    resource_type = event["configurationItem"]["resourceType"]
    # other ways to find the VM?
    event.fetch_path("configurationItem", "resourceId") if resource_type == "Aws::EC2::Instance"
  end

  def self.parse_availability_zone_ref(event)
    event.fetch_path("configurationItem", "availabilityZone")
  end
end
