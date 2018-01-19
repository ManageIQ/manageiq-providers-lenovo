# Class that provides methods to parse LXCA data to ManageIQ data.
# The parse methods inside this class works with versions:
# 1.3
# 1.4
# 2.0
# If for a specific version needs some different strategy, please
# create a subclass overriding the old with the new parse strategy, and bind this subclass
# on +VERSION_PARSERS+ constant.
module ManageIQ::Providers::Lenovo
  class Parser
    # Suported API versions.
    # To support a new version with some subclass, update this constant like this:
    # '<version>' => ManageIQ::Providers::Lenovo::<Class>
    VERSION_PARSERS = {
      'default' => ManageIQ::Providers::Lenovo::Parser,
    }.freeze

    # returns the parser of api version request
    # see the +VERSION_PARSERS+ to know what versions are supporteds
    def self.get_instance(version)
      version_parser = version.match(/^(?:(\d+)\.?(\d+))/).to_s # getting just major and minor version
      parser = VERSION_PARSERS[version_parser] # getting the class that supports the version
      parser = VERSION_PARSERS["default"] if parser.nil?
      parser.new
    end

    # parse a node object to a hash with physical servers data
    # +node+ - object containing physical server data
    def parse_physical_server(node)
      result = parse(node, dictionary::PHYSICAL_SERVER)

      result[:vendor]                     = "lenovo"
      result[:type]                       = dictionary::MIQ_TYPES["physical_server"]
      result[:power_state]                = dictionary::POWER_STATE_MAP[node.powerStatus]
      result[:health_state]               = dictionary::HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
      result[:host]                       = get_host_relationship(node.serialNumber)
      result[:location_led_state]         = find_loc_led_state(node.leds)
      result[:computer_system][:hardware] = get_hardwares(node)

      return node.uuid, result
    end

    def parse_config_pattern(config_pattern)
      return config_pattern.id, parse(config_pattern, dictionary::CONFIG_PATTERNS)
    end

    # returns a dictionary used to translate some data on the rest api
    # to system structure
    def dictionary
      ManageIQ::Providers::Lenovo::ParserDictionaryConstants
    end

    private

    # Returns a hash containing the structure described on dictionary
    # and with the values in the source.
    # +source+ - Object that will be parse to a hash
    # +dictionary+ - Hash containing the instructions to translate the object into a Hash
    # See +ParserDictionaryConstants+
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
            rescue
              # when the key doesn't correspond to a method
              source_value = source_value[source_key]
            end
          end
          result[key] = source_value
        elsif value.kind_of?(Hash)
          result[key] = parse(source, dictionary[key])
        end
      end
      result
    end

    def parse_logical_port(port)
      {
        :address => format_mac_address(port["addresses"])
      }
    end

    def format_mac_address(mac_address)
      mac_address.scan(/\w{2}/).join(":")
    end

    # Assign a physicalserver and host if server already exists and
    # some host match with physical Server's serial number
    def get_host_relationship(serial_number)
      Host.find_by(:service_tag => serial_number) ||
        Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
    end

    # Find the identification led state
    def find_loc_led_state(leds)
      identification_led = leds.to_a.find { |led| dictionary::PROPERTIES_MAP[:led_identify_name].include?(led["name"]) }
      identification_led.try(:[], "state")
    end

    def get_hardwares(node)
      {
        :disk_capacity   => get_disk_capacity(node),
        :memory_mb       => get_memory_info(node),
        :cpu_total_cores => get_total_cores(node),
        :firmwares       => get_firmwares(node),
        :guest_devices   => get_guest_devices(node)
      }
    end

    def get_disk_capacity(node)
      total_disk_cap = 0
      node.raidSettings&.each do |storage|
        storage['diskDrives']&.each do |disk|
          total_disk_cap += disk['capacity'] unless disk['capacity'].nil?
        end
      end
      total_disk_cap
    end

    def get_memory_info(node)
      node.memoryModules&.reduce(0) { |total, mem| total + mem['capacity'] }
    end

    def get_total_cores(node)
      node.processors&.reduce(0) { |total, pr| total + pr['cores'] }
    end

    def get_firmwares(node)
      node.firmware&.map { |firmware| parse_firmware(firmware) }
    end

    def get_guest_devices(node)
      guest_devices = get_addin_cards(node)
      guest_devices << parse_management_device(node)
    end

    def parse_firmware(firmware)
      {
        :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}",
        :build        => firmware["build"],
        :version      => firmware["version"],
        :release_date => firmware["date"],
      }
    end

    def get_addin_cards(node)
      parsed_addin_cards = []
      # For each of the node's addin cards, parse the addin card and then see
      # if it is already in the list of parsed addin cards. If it is, see if
      # all of its ports are already in the existing parsed addin card entry.
      # If it's not, then add the port to the existing addin card entry and
      # don't add the card again to the list of parsed addin cards.
      # This is needed because xclarity_client seems to represent each port
      # as a separate addin card. The code below ensures that each addin
      # card is represented by a single addin card with multiple ports.
      node.addinCards&.each do |node_addin_card|
        next unless get_device_type(node_addin_card) == "ethernet"

        add_card = true
        parsed_node_addin_card = parse_addin_cards(node_addin_card)

        parsed_addin_cards.each do |addin_card|
          next unless parsed_node_addin_card[:device_name] == addin_card[:device_name] ||
                      parsed_node_addin_card[:location] == addin_card[:location]

          parsed_node_addin_card[:child_devices].each do |parsed_port|
            card_found = false
            addin_card[:child_devices].each do |port|
              if parsed_port[:device_name] == port[:device_name]
                card_found = true
              end
            end
            unless card_found
              addin_card[:child_devices].push(parsed_port)
              add_card = false
            end
          end
        end

        if add_card
          parsed_addin_cards.push(parsed_node_addin_card)
        end
      end

      parsed_addin_cards
    end

    def get_device_type(card)
      device_type = ""

      unless card["name"].nil?
        card_name = card["name"].downcase
        if card_name.include?("nic") || card_name.include?("ethernet")
          device_type = "ethernet"
        end
      end
      device_type
    end

    def parse_management_device(node)
      {
        :device_type => "management",
        :network     => parse_management_network(node),
        :address     => node.macAddress
      }
    end

    def parse_management_network(node)
      {
        :ipaddress   => node.mgmtProcIPaddress,
        :ipv6address => node.ipv6Addresses.nil? ? node.ipv6Addresses : node.ipv6Addresses.join(", ")
      }
    end

    def parse_addin_cards(addin_card)
      {
        :device_name            => addin_card["productName"],
        :device_type            => get_device_type(addin_card),
        :firmwares              => get_guest_device_firmware(addin_card),
        :manufacturer           => addin_card["manufacturer"],
        :field_replaceable_unit => addin_card["FRU"],
        :location               => "Bay #{addin_card['slotNumber']}",
        :child_devices          => get_guest_device_ports(addin_card)
      }
    end

    def get_guest_device_firmware(card)
      device_fw = []

      unless card.nil?
        firmware = card["firmware"]
        unless firmware.nil?
          device_fw = firmware.map do |fw|
            parse_firmware(fw)
          end
        end
      end

      device_fw
    end

    def get_guest_device_ports(card)
      device_ports = []

      unless card.nil?
        port_info = card["portInfo"]
        physical_ports = port_info["physicalPorts"]
        physical_ports&.each do |physical_port|
          parsed_physical_port = parse_physical_port(physical_port)
          logical_ports = physical_port["logicalPorts"]
          parsed_logical_port = parse_logical_port(logical_ports[0])
          device_ports.push(parsed_logical_port.merge(parsed_physical_port))
        end
      end

      device_ports
    end

    def parse_physical_port(port)
      {
        :device_type => "physical_port",
        :device_name => "Physical Port #{port['physicalPortIndex']}"
      }
    end
  end
end
