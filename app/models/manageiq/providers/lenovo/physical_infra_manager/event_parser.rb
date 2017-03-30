module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_hash = {
      :event_type    => event.eventID,
      :source        => "LenovoXclarity",
      :message       => event.msg,
      :timestamp     => event.timeStamp,
      :lxca_severity => event.severity,
      :lxca_cn       => event.cn,
      :full_data     => event.to_hash,
      :ems_id        => ems_id
    }

    event_hash

  end
end
