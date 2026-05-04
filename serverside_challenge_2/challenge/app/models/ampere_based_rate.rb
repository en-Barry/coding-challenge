# frozen_string_literal: true

class AmpereBasedRate < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  belongs_to :plan

  validates :plan_id, presence: true
  validates :ampere, inclusion: { in: [10, 15, 20, 30, 40, 50, 60] }
  validates :rate, presence: true

  # 浮動小数点誤差を避けるため BigDecimal を返す（YAML 上は文字列で記述）
  def rate
    value = attributes[:rate]
    return nil if value.nil?

    value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
  end
end
