require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class PhysicalServerParser < ComponentParser
      class << self
        #
        # parse a node object to a hash with physical servers data
        #
        # @param [XClarityClient::Node] node - object containing physical server data
        #
        # @return [Hash] containing the physical server information
        #
        def parse_physical_server(node, rack = nil)
          result = parse(node, ParserDictionaryConstants::PHYSICAL_SERVER)

          # Keep track of the rack where this server is in, if it is in any rack
          result[:physical_rack]              = rack if rack

          result[:vendor]                     = "lenovo"
          result[:type]                       = ParserDictionaryConstants::MIQ_TYPES["physical_server"]
          result[:power_state]                = ParserDictionaryConstants::POWER_STATE_MAP[node.powerStatus]
          result[:health_state]               = ParserDictionaryConstants::HEALTH_STATE_MAP[node.cmmHealthState.nil? ? node.cmmHealthState : node.cmmHealthState.downcase]
          result[:host]                       = get_host_relationship(node.serialNumber)
          result[:location_led_state]         = find_loc_led_state(node.leds)
          result[:computer_system][:hardware] = get_hardwares(node)

          return node.uuid, result
        end

        private

        # Assign a physicalserver and host if server already exists and
        # some host match with physical Server's serial number
        def get_host_relationship(serial_number)
          Host.find_by(:service_tag => serial_number) ||
            Host.joins(:hardware).find_by('hardwares.serial_number' => serial_number)
        end

        # Find the identification led state
        def find_loc_led_state(leds)
          identification_led = leds.to_a.find { |led| ParserDictionaryConstants::PROPERTIES_MAP[:led_identify_name].include?(led["name"]) }
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
          total_disk_cap.positive? ? total_disk_cap : nil
        end

        def get_memory_info(node)
          total_memory_gigabytes = node.memoryModules&.reduce(0) { |total, mem| total + mem['capacity'] }
          total_memory_gigabytes * 1024 # convert to megabytes
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

          cards_to_parse = select_cards_to_parse(node)

          # For each of the node's addin cards, parse the addin card and then see
          # if it is already in the list of parsed addin cards. If it is, see if
          # all of its ports are already in the existing parsed addin card entry.
          # If it's not, then add the port to the existing addin card entry and
          # don't add the card again to the list of parsed addin cards.
          # This is needed because xclarity_client seems to represent each port
          # as a separate addin card. The code below ensures that each addin
          # card is represented by a single addin card with multiple ports.
          cards_to_parse.each do |node_addin_card|
            next unless get_device_type(node_addin_card) == "ethernet"

            add_card = true
            parsed_node_addin_card = parse_addin_cards(node_addin_card)

            parsed_addin_cards.each do |addin_card|
              next unless parsed_node_addin_card[:device_name] == addin_card[:device_name] ||
                          parsed_node_addin_card[:location] == addin_card[:location]

              parsed_node_addin_card[:child_devices].each do |parsed_port|
                card_found = false
                add_card = false
                addin_card[:child_devices].each do |port|
                  if parsed_port[:device_name] == port[:device_name]
                    card_found = true
                  end
                end
                unless card_found
                  addin_card[:child_devices].push(parsed_port)
                end
              end
            end

            if add_card
              parsed_addin_cards.push(parsed_node_addin_card)
            end
          end

          parsed_addin_cards
        end

        def select_cards_to_parse(component)
          pci_devices = component.try(:pciDevices)
          addin_cards = component.try(:addinCards)

          devices = []
          devices.concat(pci_devices) if pci_devices.present?
          devices.concat(addin_cards) if addin_cards.present?
          devices
        end

        def get_device_type(card)
          device_type = ""

          unless card["name"].nil?
            card_name = card["name"].downcase
            if card["class"] == "Network controller" || card_name.include?("nic") || card_name.include?("ethernet")
              device_type = "ethernet"
            end
          end
          device_type
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

        def parse_management_device(node)
          {
            :device_type => "management",
            :network     => parse_management_network(node),
            :address     => node.macAddress
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

        def parse_management_network(node)
          {
            :ipaddress   => node.mgmtProcIPaddress,
            :ipv6address => node.ipv6Addresses.nil? ? node.ipv6Addresses : node.ipv6Addresses.join(", ")
          }
        end

        def parse_logical_port(port)
          {
            :address => format_mac_address(port["addresses"])
          }
        end

        def format_mac_address(mac_address)
          mac_address.scan(/\w{2}/).join(":")
        end
      end
    end
  end
end
