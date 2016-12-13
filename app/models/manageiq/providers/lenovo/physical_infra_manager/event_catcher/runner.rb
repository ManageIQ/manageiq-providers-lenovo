class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    @event_monitor_handle&.stop
  ensure
    reset_event_monitor_handle
  end

  def monitor_events
    raise "event_monitor_handle is nil" if event_monitor_handle.nil?
    event_monitor_handle.start
    event_monitor_handle.each_batch do |events|

      # _log.debug { "#{log_prefix} Received event #{event.localLogID}" }
      event_monitor_running
      $log.info ("Specific monitor_events method called.")

      events.each { |event| @queue.enq event }
    end
  ensure
    stop_event_monitor
  end

  def process_event(event)
    # if filtered?(event)
    #   _log.info "#{log_prefix} Skipping filtered Lenovo event [#{event["messageId"]}]"
    # else
      # _log.info "#{log_prefix} Caught event [#{event["messageId"]}]"
      # event_hash = ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser.event_to_hash(event, @cfg[:ems_id])
      EmsEvent.add_queue('add', @cfg[:ems_id], event)
    # end
  end

  private

  def filtered?(event)
    filtered_events.include?(event["messageType"])
  end

  def event_monitor_handle
    @event_monitor_handle ||= begin
      stream = ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream.new(@ems)
      stream
    end
  end

  def reset_event_monitor_handle
    @event_monitor_handle = nil
  end
end
