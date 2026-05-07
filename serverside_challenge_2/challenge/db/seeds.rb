# frozen_string_literal: true

def upsert!(model, filename, attribute_keys)
  YAML.load_file(Rails.root.join('db/data', filename)).each do |attrs|
    record = model.find_or_initialize_by(id: attrs['id'])
    record.assign_attributes(attrs.slice(*attribute_keys.map(&:to_s)))
    record.save!
  end
end

upsert!(Provider, 'providers.yml', %i[name])
upsert!(Plan, 'plans.yml', %i[name provider_id])
upsert!(AmpereBasedRate, 'ampere_based_rates.yml', %i[plan_id ampere rate])
upsert!(UsageBasedRate, 'usage_based_rates.yml', %i[plan_id kilowatt_hour_low kilowatt_hour_high rate])

[Provider, Plan, AmpereBasedRate, UsageBasedRate].each do |model|
  max_id = model.maximum(:id).to_i
  next if max_id.zero?

  ActiveRecord::Base.connection.execute(
    "SELECT setval(pg_get_serial_sequence('#{model.table_name}', 'id'), #{max_id})"
  )
end
