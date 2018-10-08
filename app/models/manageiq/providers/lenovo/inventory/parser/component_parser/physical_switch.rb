module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::PhysicalSwitch < Inventory::Parser::ComponentParser
    # Mapping between fields inside a [XClarityClient::Switch] to a [Hash] with symbols of PhysicalSwitch fields
    PHYSICAL_SWITCH = {
      :name                   => 'name',
      :uid_ems                => 'uuid',
      :switch_uuid            => 'uuid',
      :power_state            => :power_state,
      :type                   => :type,
      :health_state           => :health_state,
      :physical_network_ports => nil, #:physical_network_ports,
      :hardware               => {
        :firmwares => nil, #:firmwares,
        :networks  => nil, #:networks
      },
      :asset_detail           => {
        :product_name           => 'productName',
        :serial_number          => 'serialNumber',
        :part_number            => 'partNumber',
        :field_replaceable_unit => 'FRU',
        :description            => 'description',
        :manufacturer           => 'manufacturer'
      }
    }.freeze

    def build(switch_xclarity)
      properties = parse_physical_switch(switch_xclarity)

      switch = @persister.physical_switches.build(properties)

      build_associations(switch, switch_xclarity)

      switch
    end

    #
    # Parses a switch into a Hash
    #
    # @param physical_switch [XClarityClient::Switch] - object containing details for the switch
    #
    # @return [Hash] the switch data as required by the application
    #
    def parse_physical_switch(physical_switch)
      parse(physical_switch, PHYSICAL_SWITCH)
    end

    private

    def build_associations(switch, switch_xclarity)
      build_physical_network_ports(switch, switch_xclarity)
      build_hardware(switch, switch_xclarity)
      build_asset_detail(switch, switch_xclarity)
    end

    def build_hardware(switch, switch_xclarity)
      hardware = @persister.physical_switch_hardwares.build(
        :physical_switch => switch
      )

      build_firmwares(hardware, switch_xclarity)
      build_networks(hardware, switch_xclarity)
    end

    def build_firmwares(hardware, switch_xclarity)
      switch_xclarity.firmware&.each do |firmware|
        components(:firmwares).build(firmware,
                                     :physical_switch_firmwares,
                                     :belongs_to => :resource,
                                     :object     => hardware)
      end
    end

    def build_networks(hardware, switch_xclarity)
      networks(switch_xclarity).each do |network_properties|
        add_parent(network_properties, :belongs_to => :hardware, :object => hardware)
        @persister.physical_switch_networks.build(network_properties)
      end
    end

    def build_physical_network_ports(switch, switch_xclarity)
      components(:physical_network_ports).build_physical_switch_ports(switch_xclarity,
                                                                      :belongs_to => :physical_switch,
                                                                      :object     => switch)
    end

    def build_asset_detail(switch, switch_xclarity)
      super(switch, switch_xclarity, PHYSICAL_SWITCH[:asset_detail])
    end

    def power_state(switch)
      state = switch.powerState
      if !state.nil? && %w(on off).include?(state.downcase)
        state.downcase
      else
        state
      end
    end

    def type(_switch)
      'ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch'
    end

    def health_state(switch)
      HEALTH_STATE_MAP[switch.overallHealthState.nil? ? switch.overallHealthState : switch.overallHealthState.downcase]
    end

    def networks(physical_switch)
      get_parsed_switch_ip_interfaces_by_key(
        physical_switch.ipInterfaces,
        'IPv4assignments',
        physical_switch.ipv4Addresses,
        false
      ) + get_parsed_switch_ip_interfaces_by_key(
        physical_switch.ipInterfaces,
        'IPv6assignments',
        physical_switch.ipv6Addresses,
        true
      )
    end

    def get_parsed_switch_ip_interfaces_by_key(ip_interfaces, key, address_list, is_ipv6 = false)
      ip_interfaces&.flat_map { |interface| interface[key] }
        .select { |assignment| address_list.include?(assignment['address']) }
        .map { |assignment| parse_network(assignment, is_ipv6) }
    end

    def parse_network(assignment, is_ipv6 = false)
      {
        :subnet_mask     => assignment['subnet'],
        :default_gateway => assignment['gateway'],
        :ipaddress       => (assignment['address'] unless is_ipv6),
        :ipv6address     => (assignment['address'] if is_ipv6)
      }
    end
  end
end
