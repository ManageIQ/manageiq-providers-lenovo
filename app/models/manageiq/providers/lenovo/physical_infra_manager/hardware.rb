module ManageIQ::Providers
  class Lenovo::PhysicalInfraManager::Hardware < ::Hardware
    has_many :management_devices, -> { where("device_type = 'management'") }, :class_name => "GuestDevice", :foreign_key => :hardware_id
  end
end
