module ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer::Operations
  extend ActiveSupport::Concern

  include_concern 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::Operations::ComponentAnsibleSender'
end
