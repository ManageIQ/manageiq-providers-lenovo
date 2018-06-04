module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type            => event.msgID,
      :ems_ref               => event.cn,
      :source                => "LenovoXclarity",
      :physical_component_id => get_physical_component_id(event.componentID),
      :message               => event.msg,
      :timestamp             => event.timeStamp,
      :full_data             => event.to_hash,
      :ems_id                => ems_id,
    }

    event_hash
  end

  def self.get_physical_component_id(ems_ref)
    PhysicalComponent.find_by(:ems_ref => ems_ref).try(:id)
  end
end
