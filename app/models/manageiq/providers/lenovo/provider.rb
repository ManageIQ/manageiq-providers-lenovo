class ManageIQ::Providers::Lenovo::Provider < ::Provider
  # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
  has_one :ph_infra_manager,
          :foreign_key => "provider_id",
          :class_name  => "ManageIQ::Providers::Lenovo::PhysicalInfraManager",
          :autosave    => true
  # rubocop:enable Rails/HasManyOrHasOneDependent,Rails/InverseOf

  validates :name, :presence => true, :uniqueness => true
end
