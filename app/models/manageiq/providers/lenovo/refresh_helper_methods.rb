module ManageIQ::Providers::Lenovo::RefreshHelperMethods
  extend ActiveSupport::Concern

  module ClassMethods
    def ems_inv_to_hashes(ems, options = nil)
      new(ems, options).ems_inv_to_hashes
    end
  end
end
