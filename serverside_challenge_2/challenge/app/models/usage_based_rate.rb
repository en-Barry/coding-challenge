# frozen_string_literal: true

class UsageBasedRate < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  fields :plan_id, :kilowatt_hour_low, :kilowatt_hour_high, :rate

  belongs_to :plan

  validates :plan_id, :kilowatt_hour_low, :kilowatt_hour_high, :rate, presence: true
  validates :plan_id,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :kilowatt_hour_low, :kilowatt_hour_high,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate :low_must_not_exceed_high
  validate :rate_must_be_number

  # 浮動小数点誤差を避けるため BigDecimal を返す（YAML 上は文字列で記述）
  def rate
    value = attributes[:rate]
    return nil if value.nil?

    value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
  end

  # rate getter は BigDecimal 変換時に ArgumentError を投げ得るため、
  # バリデーション時は raw 値を直接読むようにする（presence などが getter を呼んで落ちるのを回避）
  def read_attribute_for_validation(key)
    return attributes[:rate] if key.to_sym == :rate

    super
  end

  private

  def low_must_not_exceed_high
    return if kilowatt_hour_low.nil? || kilowatt_hour_high.nil?
    return unless kilowatt_hour_low > kilowatt_hour_high

    errors.add(:kilowatt_hour_low, :must_not_exceed_high)
  end

  # rate getter は BigDecimal 変換時に ArgumentError を投げ得るため、
  # numericality ではなく raw 値を直接読む custom validator で型・範囲を検証する
  def rate_must_be_number
    value = attributes[:rate]
    return if value.nil?

    decimal = BigDecimal(value.to_s)
    errors.add(:rate, :greater_than_or_equal_to, count: 0) if decimal.negative?
  rescue ArgumentError
    errors.add(:rate, :not_a_number)
  end
end
