module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type         => event.eventID,
      :ems_ref            => event.cn,
      :source             => "LenovoXclarity",
      :physical_server_id => get_physical_server_id(event.componentID),
      :message            => event.msg,
      :timestamp          => event.timeStamp,
      :full_data          => event.to_hash,
      :ems_id             => ems_id
    }

    event_hash
  end

  def self.get_physical_server_id(ems_ref)
    PhysicalServer.find_by(:ems_ref => ems_ref).try(:id)
  end
end
