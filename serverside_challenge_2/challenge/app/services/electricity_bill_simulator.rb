# frozen_string_literal: true

class ElectricityBillSimulator
  VALID_AMPERES = [10, 15, 20, 30, 40, 50, 60].freeze
  MAX_KWH = 9999

  def self.call(ampere:, kwh:)
    new(ampere: ampere, kwh: kwh).call
  end

  def initialize(ampere:, kwh:)
    @ampere = Integer(ampere)
    @kwh = Integer(kwh)

    validate!
  end

  def call
    Plan.all
        .filter_map { |plan| pair_with_price(plan) }
        .sort_by { |plan, price| [price, plan.provider_id, plan.id] }
        .map { |plan, price| { provider_name: plan.provider.name, plan_name: plan.name, price: price } }
  end

  private

  def validate!
    unless VALID_AMPERES.include?(@ampere)
      raise ArgumentError, "ampere must be one of #{VALID_AMPERES} (got #{@ampere})"
    end
    raise ArgumentError, "kwh must be between 0 and #{MAX_KWH} (got #{@kwh})" unless (0..MAX_KWH).cover?(@kwh)
  end

  # アンペア非対応プランは nil を返し、filter_map で除外する
  def pair_with_price(plan)
    base = base_price(plan)
    return nil if base.nil?

    [plan, (base + usage_price(plan)).floor.to_i]
  end

  # 従量課金のみプランは基本料金 0、それ以外は ampere 一致レコードが無ければ nil
  def base_price(plan)
    return BigDecimal(0) if plan.metered_only?

    plan.ampere_based_rates.detect { |r| r.ampere == @ampere }&.rate
  end

  def usage_price(plan)
    plan.usage_based_rates.sum(BigDecimal(0)) do |usage_rate|
      usage_rate.rate * billable_kwh_for(usage_rate)
    end
  end

  def billable_kwh_for(usage_rate)
    upper = [@kwh, usage_rate.kilowatt_hour_high].min
    consumed = upper - usage_rate.kilowatt_hour_low + 1

    [consumed, 0].max
  end
end
