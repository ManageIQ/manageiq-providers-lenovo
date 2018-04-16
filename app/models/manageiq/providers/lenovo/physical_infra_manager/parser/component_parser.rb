module ManageIQ::Providers::Lenovo
  #
  # Superclass extended by all classes that parses LXCA components
  # to a MiQ format
  #
  class PhysicalInfraManager::Parser::ComponentParser
    #
    # Returns a hash containing the structure described on dictionary
    # and with the values in the source.
    #
    # @param source     - Object that will be parse to a hash
    # @param dictionary - Hash containing the instructions to translate the object into a Hash
    #
    # @see ParserDictionaryConstants
    #
    def self.parse(source, dictionary)
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
