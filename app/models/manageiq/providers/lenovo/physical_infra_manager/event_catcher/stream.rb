class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream

  # Creates an event monitor
  #
  def initialize(ems)
    @ems                  = ems
    @event_monitor_handle = event_monitor_handle
    @collecting_events    = false
    @since                = nil
  end

  # Start capturing events
  def start
    @collecting_events = true
  end

  # Stop capturing events
  def stop
    @event_monitor_handle = nil
    @collecting_events = false
  end

  def each_batch
    yield get_events.collect { |e| ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser.event_to_hash(e,@ems.id) }
  end

  def event_monitor_handle
    @event_monitor_handle ||= create_event_monitor_handle @ems
  end

  private

  def get_events
    @event_monitor_handle.discover_events
  end

  def create_event_monitor_handle(ems)
    ems_auth = ems.authentications.first

    ems.connect({:user => ems_auth.userid,
                 :pass => ems_auth.password,
                 :host =>  ems.endpoints.first.hostname})
  end


end
