module ManageIQ::Providers::Lenovo
  class Inventory::Parser::ComponentParser::PhysicalDisk < Inventory::Parser::ComponentParser
    PHYSICAL_DISK = {
      :model           => 'model',
      :vendor          => 'vendorName',
      :status          => 'status',
      :location        => 'location',
      :serial_number   => 'serialNumber',
      :health_state    => 'health',
      :controller_type => 'type',
      :disk_size       => 'size'
    }.freeze

    def build(driver, index, storage = nil, canister = nil)
      parsed_disk = parse_disk(driver, storage, index)

      add_parent(parsed_disk, :belongs_to => :physical_storage, :object => storage) if storage
      add_parent(parsed_disk, :belongs_to => :canister, :object => canister) if canister
      physical_disk = @persister.physical_disks.build(parsed_disk)

      physical_disk
    end

    def total_space(components)
      total_space = 0
      components.each do |component|
        component['drives'].each do |driver|
          total_space += driver['size'].to_i
        end
      end
      total_space
    end

    def parse_disk(driver, storage, index)
      result = {}
      PHYSICAL_DISK.each_pair do |key, driver_key|
        result[key] = driver[driver_key]
      end
      result[:ems_ref] = storage[:ems_ref] + '_' + index
      result
    end
  end
end
