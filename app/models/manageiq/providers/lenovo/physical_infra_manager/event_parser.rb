module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(data, ems_id)
    event = filter_data(data)
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

  def self.filter_data(data)
    {
      :component_id   => data.componentID,
      :component_type => data.typeText,
      :event_type     => data.msgID,
      :ems_ref        => data.cn,
      :message        => data.msg,
      :parent_uuid    => data.senderUUID,
      :parent_name    => data.systemName,
      :parent_model   => data.systemTypeModelText,
      :parent_type    => data.systemTypeText,
      :severity_id    => data.severity,
      :severity       => data.severityText,
      :source         => 'LenovoXclarity',
      :timestamp      => data.timeStamp,
    }
  end

  def self.get_physical_server_id(ems_ref)
    PhysicalServer.find_by(:ems_ref => ems_ref).try(:id)
  end
end
