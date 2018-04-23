#
# An Authenticatable Provider must be able to do some operations with its credentials
#
module ManageIQ::Providers::Lenovo::PhysicalInfraManager::AuthenticatableProvider
  # (see AuthenticationMixin#raw_change_password)
  def raw_change_password(current_password, new_password)
    _log.info("Password change requested for physical provider '#{name}' and userId #{authentication_userid}")

    response = connect.change_user_password(current_password, new_password)

    unless response[:changed]
      _log.info("Password change request was not successfully completed due to: #{response[:message]}")
      raise MiqException::Error, _(response[:message])
    end

    _log.info("Password change request was successfully completed")
    true
  end
end
