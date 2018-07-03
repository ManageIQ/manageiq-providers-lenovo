module ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser
  CHASSIS = 'Chassis'.freeze
  SERVER  = %w(Node Power Processor System).freeze
  SWITCH  = 'Switch'.freeze

  class << self
    def event_to_hash(data, ems_id)
      event = filter_data(data)
      event_hash = {
        :event_type => event[:event_type],
        :ems_ref    => event[:ems_ref],
        :source     => event[:source],
        :message    => event[:message],
        :timestamp  => event[:timestamp],
        :full_data  => event,
        :ems_id     => ems_id
      }

      event_hash.merge!(event_resources(event))
    end

    def filter_data(data)
      {
        :component_id   => data.componentID,
        :component_type => data.typeText,
        :event_type     => data.msgID,
        :ems_ref        => data.cn,
        :message        => data.msg,
        :parent_uuid    => data.sourceID,
        :parent_name    => data.systemName,
        :parent_model   => data.systemTypeModelText,
        :parent_type    => data.systemTypeText,
        :severity_id    => data.severity,
        :severity       => data.severityText,
        :source         => 'LenovoXclarity',
        :timestamp      => data.timeStamp,
      }
    end

    private

    def event_resources(event)
      event_resources = {}

      if event[:parent_type] == CHASSIS
        event_resources[:physical_chassis_id] = get_resource_id(PhysicalChassis, event[:parent_uuid])
      end

      if event[:component_type] == SWITCH
        event_resources[:physical_switch_id] = get_resource_id(PhysicalSwitch, event[:component_id])
      elsif SERVER.include?(event[:component_type])
        event_resources[:physical_server_id] = get_resource_id(PhysicalServer, event[:component_id])
      else
        $log.error("The event of type #{event[:component_type]} is not supported")
      end

      event_resources
    end

    def get_resource_id(resource, uid_ems)
      resource.find_by(:uid_ems => uid_ems).try(:id)
    end
  end
end
