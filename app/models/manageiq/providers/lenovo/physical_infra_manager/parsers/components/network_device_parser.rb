require_relative 'component_parser'

module ManageIQ::Providers::Lenovo
  module Parsers
    class NetworkDeviceParser < ComponentParser
      class << self
        #
        # @param component - component that has network devices to be parseds
        #
        def parse_network_devices(component)
          all_devices = select_network_devices(component)

          distinct_devices = distinct_network_devices(all_devices)

          distinct_devices.map do |device|
            parsed_device = parse_device(device)
            parsed_device[:child_devices] = parse_child_devices(device, all_devices)
            parsed_device
          end
        end

        private

        #
        # Selects all network devices.
        #   The network devices could be in `pciDevices` or `addinCards` prop
        #
        # @return a list with all network devices of the component
        #   (it could have duplicated entries if the entry is in both properties)
        #
        def select_network_devices(component)
          pci_devices = component.try(:pciDevices).try(:select) { |device| network_device?(device) }
          addin_cards = component.try(:addinCards).try(:select) { |device| network_device?(device) }

          devices = []
          devices.concat(pci_devices) if pci_devices.present?
          devices.concat(addin_cards) if addin_cards.present?
          devices
        end

        #
        # Distincts the network devices by pciSubID property (remove duplicated entries)
        #
        def distinct_network_devices(devices)
          devices.uniq { |device| mount_uuid(device) }
        end

        #
        # Verifies if a device is a network device by it name or it class
        #
        def network_device?(device)
          device_name = (device["productName"] ? device["productName"] : device["name"]).try(:downcase)
          device["class"] == "Network controller" || device_name =~ /nic/ || device_name =~ /ethernet/
        end

        def parse_device(device)
          {
            :uid_ems                => mount_uuid(device),
            :device_name            => device["productName"] ? device["productName"] : device["name"],
            :device_type            => "ethernet",
            :firmwares              => parse_device_firmware(device),
            :manufacturer           => device["manufacturer"],
            :field_replaceable_unit => device["FRU"],
            :location               => device['slotNumber'] ? "Bay #{device['slotNumber']}" : nil,
          }
        end

        def parse_device_firmware(device)
          device_fw = []

          firmware = device["firmware"]
          unless firmware.nil?
            device_fw = firmware.map do |fw|
              parse_firmware(fw)
            end
          end

          device_fw
        end

        def parse_child_devices(device, all_devices)
          ports = all_devices.select { |device_with_port| device["pciSubID"] == device_with_port["pciSubID"] }

          parsed_ports = []

          ports.each do |port|
            device_parced_ports = parse_ports(port)
            parsed_ports.concat(device_parced_ports) if device_parced_ports.present?
          end

          parsed_ports.uniq { |port| port[:device_name] }
        end

        def parse_ports(port)
          port_info = port["portInfo"]
          physical_ports = port_info["physicalPorts"]
          physical_ports&.map do |physical_port|
            parsed_physical_port = parse_physical_port(physical_port)
            logical_ports = physical_port["logicalPorts"]
            parsed_logical_port = parse_logical_port(logical_ports[0])
            parsed_logical_port[:uid_ems] = mount_uuid(port, true, physical_port['physicalPortIndex'])
            parsed_logical_port.merge!(parsed_physical_port)
            parsed_logical_port
          end
        end

        def parse_physical_port(port)
          {
            :device_type => "physical_port",
            :device_name => "Physical Port #{port['physicalPortIndex']}"
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

        def parse_firmware(firmware)
          {
            :name         => "#{firmware["role"]} #{firmware["name"]}-#{firmware["status"]}",
            :build        => firmware["build"],
            :version      => firmware["version"],
            :release_date => firmware["date"],
          }
        end

        #
        # Mounts the uuid for the devices
        #   For those devices that hasn't an uuid this method uses others properties to mount one
        #
        # @param device       - device that needs an uuid
        # @param child_device - if the device is a child device, it uuid will be the same
        # @param port_number  - number of the port of the child device that will be concat to the uuid
        #
        def mount_uuid(device, child_device = false, port_number = nil)
          uuid = device["uuid"] || "#{device['pciBusNumber']}#{device['pciDeviceNumber']}"
          return uuid + port_number.to_s if child_device
          uuid
        end
      end
    end
  end
end
