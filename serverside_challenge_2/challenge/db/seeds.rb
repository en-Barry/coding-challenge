# frozen_string_literal: true

ActiveRecord::Base.transaction do
  YAML.load_file(Rails.root.join('db/data/providers.yml')).each do |attrs|
    Provider.find_or_create_by!(name: attrs.fetch('name'))
  end

  YAML.load_file(Rails.root.join('db/data/plans.yml')).each do |attrs|
    provider = Provider.find_by!(name: attrs.fetch('provider_name'))
    Plan.find_or_create_by!(provider: provider, name: attrs.fetch('name'))
  end

  YAML.load_file(Rails.root.join('db/data/ampere_based_rates.yml')).each do |attrs|
    plan = Plan.find_by!(name: attrs.fetch('plan_name'))
    record = AmpereBasedRate.find_or_initialize_by(plan: plan, ampere: attrs.fetch('ampere'))
    record.update!(rate: attrs.fetch('rate'))
  end

  YAML.load_file(Rails.root.join('db/data/usage_based_rates.yml')).each do |attrs|
    plan = Plan.find_by!(name: attrs.fetch('plan_name'))
    record = UsageBasedRate.find_or_initialize_by(
      plan: plan,
      kilowatt_hour_low: attrs.fetch('kilowatt_hour_low'),
      kilowatt_hour_high: attrs.fetch('kilowatt_hour_high')
    )
    record.update!(rate: attrs.fetch('rate'))
  end
end
