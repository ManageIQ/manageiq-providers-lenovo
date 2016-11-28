class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream

  # Creates an event monitor
  #
  def initialize(ems)
    @ems = ems
    @collecting_events = false
    @since = nil
  end

  # Start capturing events
  def start
    @collecting_events = true
  end

  # Stop capturing events
  def stop
    @collecting_events = false
  end


end
