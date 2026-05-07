# frozen_string_literal: true

FactoryBot.define do
  factory :ampere_based_rate do
    association :plan
    ampere { 30 }
    rate { '858.00' }
  end
end
