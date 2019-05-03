module ManageIQ::Providers::Lenovo
  module PhysicalInfraManager::PhysicalServer::Provisioning
    def update_firmware
      with_provider_object do |system|
        #  raise MiqException::MiqProvisionError, 'at least one MAC address is needed for provisioning'
      end
      puts "updating_firmware"
    end

    def update_configuration
      with_provider_object do |system|
        #raise MiqException::MiqProvisionError, 'Cannot override boot order' if response.status >= 400
      end
      # TODO: we perform force reboot which will fail in some cases. Need to handle with supports mixin.
      #restart_now
      puts "updating_configuration"
    end

    def powered_on_now?
      # TODO(miha-plesko): we should rely on VMDB state instead contacting provider.
      # Update implementation once we have event-driven targeted refresh implemented.
      #with_provider_object { |system| return system.PowerState.to_s.downcase == 'on' }
      true 
    end

  end
end
