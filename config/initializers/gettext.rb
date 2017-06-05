Vmdb::Gettext::Domains.add_domain(
  'ManageIQ_Providers_Nuage',
  ManageIQ::Providers::Nuage::Engine.root.join('locale').to_s,
  :po
)
