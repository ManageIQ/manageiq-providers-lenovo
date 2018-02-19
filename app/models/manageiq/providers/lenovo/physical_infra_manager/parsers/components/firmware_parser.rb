require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class FirmwareParser < ComponentParser
      class << self
        #
        # Parses a firmware into a Hash
        #
        # @param [Hash] firmware - object containing details for the firmware
        #
        # @return [Hash] the firmware as required by the application
        #
        def parse_firmware(firmware)
          {
            :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}".strip,
            :build        => firmware["build"],
            :version      => firmware["version"],
            :release_date => firmware["date"],
          }
        end
      end
    end
  end
end
