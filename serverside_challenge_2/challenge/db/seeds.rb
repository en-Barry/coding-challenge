# frozen_string_literal: true

seed_config = [
  { model: Provider,        file: 'providers.yml',          keys: %i[name] },
  { model: Plan,            file: 'plans.yml',              keys: %i[name provider_id] },
  { model: AmpereBasedRate, file: 'ampere_based_rates.yml', keys: %i[plan_id ampere rate] },
  { model: UsageBasedRate,  file: 'usage_based_rates.yml',
    keys: %i[plan_id kilowatt_hour_low kilowatt_hour_high rate] }
].freeze

seed_data = seed_config.map do |config|
  config.merge(records: YAML.load_file(Rails.root.join('db/data', config[:file])))
end

ActiveRecord::Base.transaction do
  seed_data.reverse_each do |config|
    ids_in_yaml = config[:records].pluck('id')
    config[:model].where.not(id: ids_in_yaml).destroy_all
  end

  seed_data.each do |config|
    config[:records].each do |attrs|
      record = config[:model].find_or_initialize_by(id: attrs['id'])
      record.assign_attributes(attrs.slice(*config[:keys].map(&:to_s)))
      record.save!
    end

    max_id = config[:model].maximum(:id).to_i
    next if max_id.zero?

    ActiveRecord::Base.connection.execute(
      "SELECT setval(pg_get_serial_sequence('#{config[:model].table_name}', 'id'), #{max_id})"
    )
  end
end
