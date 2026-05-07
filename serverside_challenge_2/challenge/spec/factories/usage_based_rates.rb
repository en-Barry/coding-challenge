# frozen_string_literal: true

FactoryBot.define do
  factory :usage_based_rate do
    association :plan
    kilowatt_hour_low { 1 }
    kilowatt_hour_high { 9999 }
    rate { '19.88' }
  end
end
