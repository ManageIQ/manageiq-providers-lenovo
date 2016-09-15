class ManageIQ::Providers::Lenovo::PhysicalInfraManager::Vm < ManageIQ::Providers::InfraManager::Vm

  # Show certain non-generic charts
  def cpu_mhz_available?
    false
  end

  def memory_mb_available?
    false
  end

end