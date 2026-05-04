# frozen_string_literal: true

class UsageBasedRate < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  belongs_to :plan

  validates :plan_id, :kilowatt_hour_low, :kilowatt_hour_high, :rate, presence: true
  validate :low_must_not_exceed_high

  # 浮動小数点誤差を避けるため BigDecimal を返す（YAML 上は文字列で記述）
  def rate
    value = attributes[:rate]
    return nil if value.nil?

    value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
  end

  private

  def low_must_not_exceed_high
    return if kilowatt_hour_low.nil? || kilowatt_hour_high.nil?
    return unless kilowatt_hour_low > kilowatt_hour_high

    errors.add(:kilowatt_hour_low, :must_not_exceed_high)
  end
end
