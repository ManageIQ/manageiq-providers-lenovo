class ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Stream
  # Creates an event monitor
  #
  def initialize(ems)
    @ems = ems
    @collect_events = true
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
    fields = [
      { :operation => 'NOT', :field => 'eventClass', :value => '200' },
      { :operation => 'NOT', :field => 'eventClass', :value => '800' }
    ]
    last_cn_event = get_last_ems_ref(@ems.id)
    cn_operation = { :operation => 'GT', :field => 'cn', :value => last_cn_event.to_s }
    fields.push(cn_operation) unless last_cn_event.nil?
    fields
  end

  def parse_events(events)
    events.collect do |data|
      event = ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventCatcher::Event.new(data).to_hash
      ManageIQ::Providers::Lenovo::PhysicalInfraManager::EventParser.event_to_hash(event, @ems.id)
    end
  end

  def events
    expression = { :filterType => 'FIELDNOTREGEXAND', :fields => filter_fields }

    opts = {'filterWith' => expression.to_json}

    connection.fetch_events(opts)
  end

  def connection
    @connection ||= create_event_connection(@ems)
  end

  def create_event_connection(ems)
    ems_auth = ems.authentications.first

    ems.connect(:user => ems_auth.userid,
                :pass => ems_auth.password,
                :host => ems.endpoints.first.hostname,
                :port => ems.endpoints.first.port)
  end

  def get_last_ems_ref(ems_id)
    EventStream.where(:ems_id => ems_id).maximum('CAST(ems_ref AS int)') || 1
  end
end
