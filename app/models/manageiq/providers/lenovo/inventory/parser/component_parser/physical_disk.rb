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

    def lazy_build(components, storage_uuid)
      total_space = 0

      components.each do |component|
        component['drives'].each do |drive|
          properties = parse_drive(drive)
          properties[:physical_storage] = @persister.physical_storages.lazy_find(storage_uuid)

          total_space += properties[:disk_size].to_i

          @persister.physical_disks.build(properties)
        end
      end

      total_space
    end

    def parse_drive(drive)
      result = {}
      PHYSICAL_DISK.each_pair do |key, drive_key|
        result[key] = drive[drive_key]
      end
      result
    end
  end
end
