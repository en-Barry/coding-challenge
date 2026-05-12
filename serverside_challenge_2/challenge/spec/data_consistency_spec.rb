# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'シードデータの整合性' do
  before { Rails.application.load_seed }

  describe 'モデルバリデーション' do
    [Provider, Plan, AmpereBasedRate, UsageBasedRate].each do |model|
      it "#{model.name} の全レコードが valid であること" do
        model.all.each do |record|
          record.valid?
          expect(record).to be_valid,
                            "#{model.name}##{record.id}: #{record.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  describe '入力可能範囲のカバレッジ' do
    it '各プラン最終段の kilowatt_hour_high が MAX_KWH 以上であること' do
      Plan.find_each do |plan|
        last_high = plan.usage_based_rates.maximum(:kilowatt_hour_high)
        expect(last_high).to be >= ElectricityBillConstants::MAX_KWH,
                             "Plan '#{plan.name}': 最終段 #{last_high} が " \
                             "MAX_KWH (#{ElectricityBillConstants::MAX_KWH}) 未満。" \
                             '入力受付した kwh が料金計算でカバーされない可能性がある (silent な料金過小算出のリスク)'
      end
    end
  end

  describe '料金レンジの連続性' do
    it '各プランの usage_based_rates の最初の段は low=1 から始まる' do
      Plan.find_each do |plan|
        sorted = plan.usage_based_rates.order(:kilowatt_hour_low)
        next if sorted.empty?

        first_low = sorted.first.kilowatt_hour_low
        expect(first_low).to eq(1), "Plan##{plan.id}: 最初の段の low は 1 のはずが #{first_low}"
      end
    end

    it '各プランの usage_based_rates は段の間に穴も重複もなく連続している' do
      Plan.find_each do |plan|
        ranges = plan.usage_based_rates.order(:kilowatt_hour_low).pluck(:kilowatt_hour_low, :kilowatt_hour_high)
        ranges.each_cons(2) do |(_, prev_high), (next_low, _)|
          expect(next_low).to eq(prev_high + 1)
        end
      end
    end
  end

  describe '業務的不変条件' do
    it '基本料金 0 円のプランが少なくとも 1 つ存在する (Looopでんき おうちプラン 等)' do
      plans_with_zero_base = Plan.all.select { |p| p.base_price_for(30) == BigDecimal(0) }
      expect(plans_with_zero_base).not_to be_empty
    end
  end
end
