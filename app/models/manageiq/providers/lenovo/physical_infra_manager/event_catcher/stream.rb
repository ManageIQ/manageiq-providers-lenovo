class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream
  # The following codes represent the event classes that we don't want on our requests.
  # Each event class corresponds to the source of the event, them being:
  #  - 200: Audit
  #  - 800: Rack or tower server
  DISREGARDED_EVENTS = %w(200 800).freeze

  #
  # Creates an event monitor
  #
  def initialize(ems)
    @timeout, @events_pool_percentage = read_event_settings
    @ems = ems
    @collect_events = true
    @last_event_ems_ref = last_event_ems_ref(@ems.id) || 0
  end

  # Stop capturing events
  def stop
    @connection = nil
    @collect_events = false
  end

  def each_batch
    $log.info('Starting collect of LXCA events ...')
    while @collect_events
      yield(parse_events(events))
    end
    $log.info('Stopping collect of LXCA events ...')
  end

  private

  def filter_fields
    filter_fields = []
    DISREGARDED_EVENTS.each do |event|
      filter_fields << { :operation => 'NOT', :field => 'eventClass', :value => event }
    end
    filter_fields << { :operation => 'GT', :field => 'cn', :value => @last_event_ems_ref.to_s }
  end

  def parse_events(events)
    return if events.blank?

    parsed_events = events.sort { |x, y| Integer(x.cn) <=> Integer(y.cn) }.collect do |event|
      ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser.event_to_hash(event, @ems.id)
    end

    # Update the @last_event_ems_ref with the new last ems_ref if to exist new events
    @last_event_ems_ref = parsed_events.last[:ems_ref].to_i
    parsed_events
  end

  def events
    expression = { :filterType => 'FIELDNOTREGEXAND', :fields => filter_fields }
    opts = {'filterWith' => expression.to_json}

    @last_cn ||= get_last_cn(opts)
    opts['headers'] = pagination if @last_event_ems_ref < @last_cn

    connection.fetch_events(opts)
  end

  def get_last_cn(opts)
    headers = { :range => 'item=0-1' }
    opts['headers'] = headers
    connection.get_last_cn(opts) # get last event cn based on the response
  end

  #
  # This method selects the range in which the events requisition will be made.
  # In order to do that, it selects 7% of the amount of events and iterates over it.
  #
  def pagination
    offset = @limit || 0
    @limit = @last_cn * @events_pool_percentage + offset

    { :range => "item=#{offset.to_i}-#{@limit.to_i}" }
  end

  def connection
    @connection ||= create_event_connection(@ems)
  end

  def create_event_connection(ems)
    ems_auth = ems.authentications.first

    ems.connect(:user    => ems_auth.userid,
                :pass    => ems_auth.password,
                :host    => ems.endpoints.first.hostname,
                :port    => ems.endpoints.first.port,
                :timeout => @timeout)
  end

  def last_event_ems_ref(ems_id)
    EventStream.where(:ems_id => ems_id).maximum('CAST(ems_ref AS int)')
  end

  def read_event_settings
    settings = ::Settings.ems.ems_lenovo.event_handling
    [settings.connection_timeout, settings.events_pool_percentage]
  end
end
