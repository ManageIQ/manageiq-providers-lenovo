module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::CompliancePolicyParser < PhysicalInfraManager::Parser::ComponentParser
    COMPLIANCE_NAME = 'No policy assigned'.freeze
    COMPLIANCE_STATUS = {
      'no'  => 'Non-compliant',
      'yes' => 'Compliant',
      ''    => 'None'
    }.freeze

    class << self
      def parse_compliance_policy(compliance_policies)
        parse_to_hash(compliance_policies)
      end

      private

      def map_by_uuid(collection)
        collection.collect do |result|
          policy_name = result['policyName']
          data = {
            :policy_name => policy_name.empty? ? COMPLIANCE_NAME : policy_name,
            :status      => "#{COMPLIANCE_STATUS[result['endpointCompliant']]} #{result['message'].join(', ')}".strip,
          }
          # Return a tuple [key, value] for each result
          [result['uuid'], data]
        end.to_h
      end

      def parse_to_hash(persisted_results)
        persisted_results.collect do |persisted_result|
          if persisted_result.xITEs.present?
            map_by_uuid(persisted_result.xITEs)
          elsif persisted_result.racklist.present?
            map_by_uuid(persisted_result.racklist)
          end
        end.compact.reduce({}, :merge)
      end
    end
  end
end
