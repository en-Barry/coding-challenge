# frozen_string_literal: true

class AmpereBasedRate < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  fields :plan_id, :ampere, :rate

  belongs_to :plan

  validates :plan_id, presence: true
  validates :plan_id, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :ampere, inclusion: { in: [10, 15, 20, 30, 40, 50, 60] }
  validates :rate, presence: true
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
