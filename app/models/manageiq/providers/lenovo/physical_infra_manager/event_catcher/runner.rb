class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    @event_monitor_handle&.stop
  ensure
    reset_event_monitor_handle
  end

  def monitor_events
    raise "event_monitor_handle is nil" if event_monitor_handle.nil?
    event_monitor_handle.start
    event_monitor_handle.each_batch do |event|
      _log.debug { "#{log_prefix} Received event #{event["messageId"]}" }
      event_monitor_running
      $logger.info { "This is a prove that shit works :D ============= DDDDDD" }
      @queue.enq event

    end
  ensure
    reset_event_monitor_handle
  end

  def process_event(event)
    # if filtered?(event)
    #   _log.info "#{log_prefix} Skipping filtered Lenovo event [#{event["messageId"]}]"
    # else
      _log.info "#{log_prefix} Caught event [#{event["messageId"]}]"
      event_hash = ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser.event_to_hash(event, @cfg[:ems_id])
      EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
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
