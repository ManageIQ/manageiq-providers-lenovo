Vmdb::Gettext::Domains.add_domain(
  'ManageIQ_Providers_Lenovo',
  ManageIQ::Providers::Lenovo::Engine.root.join('locale').to_s,
  :po
)
