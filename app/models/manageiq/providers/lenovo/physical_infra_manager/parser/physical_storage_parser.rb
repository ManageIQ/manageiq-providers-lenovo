module ManageIQ::Providers::Lenovo
  class PhysicalInfraManager::Parser::PhysicalStorageParser < PhysicalInfraManager::Parser::ComponentParser
    class << self
      #
      # Parse a storage into a hash
      #
      # @param [Hash] storage_hash - hash containing physical storage raw data
      # @param [Hash] rack - parsed physical rack data
      #
      # @return [Hash] containing the physical storage information
      #
      def parse_physical_storage(storage_hash, rack)
        storage = XClarityClient::Storage.new(storage_hash)
        result = parse(storage, parent::ParserDictionaryConstants::PHYSICAL_STORAGE)

        result[:physical_rack]              = rack if rack
        result[:type]                       = parent::ParserDictionaryConstants::MIQ_TYPES["physical_storage"]
        result[:health_state]               = parent::ParserDictionaryConstants::HEALTH_STATE_MAP[storage.cmmHealthState.nil? ? storage.cmmHealthState : storage.cmmHealthState.downcase]
        result[:computer_system][:hardware] = get_hardwares(storage)

        return storage.uuid, result
      end

      private

      def get_hardwares(storage)
        parsed_storage_network = parse(storage, parent::ParserDictionaryConstants::PHYSICAL_STORAGE_NETWORK)

        {
          :guest_devices => [{
            :device_type => "management",
            :network     => parsed_storage_network
          }]
        }
      end
    end
  end
end
