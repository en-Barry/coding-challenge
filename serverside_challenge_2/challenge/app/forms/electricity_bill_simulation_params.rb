# frozen_string_literal: true

class ElectricityBillSimulationParams
  include ActiveModel::Model

  AMPERE_VALUES = [10, 15, 20, 30, 40, 50, 60].freeze
  MAX_KWH = 9_999

  attr_writer :ampere, :kwh

  validates :ampere, presence: true,
                     inclusion: { in: AMPERE_VALUES, allow_blank: true }
  validates :kwh, presence: true,
                  numericality: {
                    only_integer: true,
                    greater_than_or_equal_to: 0,
                    less_than_or_equal_to: MAX_KWH,
                    allow_blank: true
                  }

  def ampere
    cast_to_integer(@ampere)
  end

  def kwh
    cast_to_integer(@kwh)
  end

  def jsonapi_errors
    errors.map do |error|
      {
        status: '400',
        title: I18n.t('electricity_bill_simulations.errors.title'),
        detail: error.full_message,
        source: { parameter: error.attribute.to_s }
      }
    end
  end

  private

  def cast_to_integer(value)
    return nil if value.nil? || value == ''

    Integer(value.to_s, 10)
  rescue ArgumentError
    value
  end
end
