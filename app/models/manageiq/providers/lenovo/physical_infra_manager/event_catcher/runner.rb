class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def stop_event_monitor
    @event_monitor_handle.try(:stop)
  ensure
    reset_event_monitor_handle
  end

  def monitor_events
    $log.info('Starting LXCA event catcher ...')
    raise "LXCA event_monitor_handle is nil" if event_monitor_handle.nil?
    event_monitor_handle.each_batch do |events|
      event_monitor_running
      if events.present?
        $log.info("Quantity of new LXCA events: #{events.size}")
        @queue.enq(events)
      end
      sleep_poll_normal
    end
  ensure
    $log.info('Stopping LXCA event catcher ...')
    stop_event_monitor
    $log.info('Stopped LXCA event catcher')
  end

  def process_event(event)
    EmsEvent.add_queue('add', @cfg[:ems_id], event)
  end

  private

  def filtered?(event)
    filtered_events.include?(event["messageType"])
  end

  def event_monitor_handle
    @event_monitor_handle ||= ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream.new(@ems)
  end

  def reset_event_monitor_handle
    @event_monitor_handle = nil
  end
end
