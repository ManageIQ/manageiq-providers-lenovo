class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Event
  def initialize(data)
    @data = data
  end

  def to_hash
    {
      :event_type    => @data.msgID,
      :ems_ref       => @data.cn,
      :source        => "LenovoXclarity",
      :message       => @data.msg,
      :timestamp     => @data.timeStamp,
      :component_id  => @data.componentID,
      :severity      => @data.severity,
      :severity_type => @data.severityText,
      :sender_uuid   => @data.senderUUID,
      :sender_name   => @data.systemName,
      :sender_model  => @data.systemTypeModelText,
      :sender_type   => @data.systemTypeText,
      :type          => @data.typeText
    }
  end
end
