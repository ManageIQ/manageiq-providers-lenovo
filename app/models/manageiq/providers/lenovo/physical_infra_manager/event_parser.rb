module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type         => event[:event_type],
      :ems_ref            => event[:ems_ref],
      :source             => event[:source],
      :physical_server_id => get_physical_server_id(event[:component_id]),
      :message            => event[:message],
      :timestamp          => event[:timestamp],
      :full_data          => event,
      :ems_id             => ems_id
    }

    event_hash
  end

  def self.get_physical_server_id(ems_ref)
    PhysicalServer.find_by(:ems_ref => ems_ref).try(:id)
  end
end
