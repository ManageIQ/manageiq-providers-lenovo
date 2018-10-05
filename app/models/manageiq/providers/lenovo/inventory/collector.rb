class ManageIQ::Providers::Lenovo::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :PhysicalInfraManager

  def initialize(_manager, _target)
    super

    get_version
  end

  def connection
    return @connection unless @connection.nil?

    ems_auth = manager.authentications.first
    @connection = manager.connect(:user => ems_auth.userid,
                                  :pass => ems_auth.password,
                                  :host => manager.endpoints.first.hostname,
                                  :port => manager.endpoints.first.port)
  end

  # TODO(mslemr): not used, prepared for future versioning
  def get_version
    return @version unless @version.nil?

    aicc = connection.discover_aicc
    @version = aicc.first.appliance['version'] if aicc.present?
    version_parser = @version.match(/^(?:(\d+)\.?(\d+))/).to_s if @version.present? # getting just major and minor version
  end
end
