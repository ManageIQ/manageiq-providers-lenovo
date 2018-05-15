# rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
class ManageIQ::Providers::Lenovo::Provider < ::Provider
  has_one :ph_infra_manager,
          :foreign_key => 'provider_id',
          :class_name  => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager',
          :autosave    => true

  validates :name, :presence => true, :uniqueness => true
end
# rubocop:enable Rails/HasManyOrHasOneDependent,Rails/InverseOf
