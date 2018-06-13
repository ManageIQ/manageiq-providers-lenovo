module ManageIQ::Providers::Lenovo
  #
  # Superclass extended by all classes that parses LXCA components
  # to a MiQ format
  #
  class PhysicalInfraManager::Parser::ComponentParser
    class << self
      GUEST_DEVICE = {
        :manufacturer           => 'manufacturer',
        :field_replaceable_unit => 'FRU',
        :controller_type        => 'class'
      }.freeze

      HEALTH_STATE_MAP = {
        'normal'          => 'Valid',
        'non-critical'    => 'Valid',
        'warning'         => 'Warning',
        'critical'        => 'Critical',
        'unknown'         => 'None',
        'minor-failure'   => 'Critical',
        'major-failure'   => 'Critical',
        'non-recoverable' => 'Critical',
        'fatal'           => 'Critical',
        nil               => 'Unknown'
      }.freeze

      MIQ_TYPES = {
        'physical_server'  => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer',
        'physical_switch'  => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch',
        'physical_storage' => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalStorage',
        'physical_chassis' => 'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalChassis'
      }.freeze

      POWER_STATE_MAP = {
        8  => 'On',
        5  => 'Off',
        18 => 'Standby',
        0  => 'Unknown'
      }.freeze

      PROPERTIES_MAP = {
        :led_identify_name => %w(Identification Identify)
      }.freeze

      private_constant :GUEST_DEVICE
      private_constant :HEALTH_STATE_MAP
      private_constant :MIQ_TYPES
      private_constant :POWER_STATE_MAP
      private_constant :PROPERTIES_MAP

      #
      # Returns a hash containing the structure described on dictionary
      # and with the values in the source.
      #
      # @param source     - Object that will be parse to a hash
      # @param dictionary - Hash containing the instructions to translate the object into a Hash
      #
      # @see ParserDictionaryConstants
      #
      def parse(source, dictionary)
        result = {}
        dictionary&.each do |key, value|
          if value.kind_of?(String)
            next if value.empty?
            source_keys = value.split('.') # getting source keys navigation
            source_value = source
            source_keys.each do |source_key|
              begin
                attr_method = source_value.method(source_key) # getting method to get the attribute value
                source_value = attr_method.call
              rescue NameError
                # when the key doesn't correspond to a method
                source_value = source_value[source_key]
              end
            end
            result[key] = source_value.kind_of?(String) ? source_value.strip.presence : source_value
          elsif value.kind_of?(Hash)
            result[key] = parse(source, dictionary[key])
          end
        end
        result
      end
    end
  end
end
