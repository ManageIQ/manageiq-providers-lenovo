module PhysicalInfraSpecCommon
  extend ActiveSupport::Concern

  MODELS = %i(
    ext_management_system physical_rack physical_chassis physical_server
    physical_switch physical_storage physical_disk customization_script
  ).freeze

  def serialize_inventory
    skip_atributes = %w(created_at updated_at last_refresh_date updated_on)
    inventory = {}
    PhysicalInfraSpecCommon::MODELS.each do |rel|
      inventory[rel] = rel.to_s.classify.constantize.all.collect do |e|
        e.attributes.except(*skip_atributes)
      end
    end

    inventory
  end

  def assert_models_not_changed(inventory_before, inventory_after)
    aggregate_failures do
      PhysicalInfraSpecCommon::MODELS.each do |model|
        expect(inventory_after[model].count).to eq(inventory_before[model].count), "#{model} count"\
               " doesn't fit \nexpected: #{inventory_before[model].count}\ngot#{inventory_after[model].count}"

        inventory_after[model].each do |item_after|
          item_before = inventory_before[model].detect { |i| i["id"] == item_after["id"] }
          expect(item_after).to eq(item_before), \
                                "class: #{model.to_s.classify}\nexpected: #{item_before}\ngot: #{item_after}"
        end
      end
    end
  end
end
