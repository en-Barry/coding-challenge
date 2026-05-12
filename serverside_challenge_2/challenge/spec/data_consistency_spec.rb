# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'YAMLデータ整合性' do
  [Provider, Plan, AmpereBasedRate, UsageBasedRate].each do |model|
    it "#{model.name} の全レコードが valid であること" do
      model.all.each do |record|
        # 第2引数のメッセージは expect 呼び出し前に評価されるため、
        # 先に valid? を呼んで errors を確定させてから組み立てる
        record.valid?
        expect(record).to be_valid,
                          "#{model.name}##{record.id}: #{record.errors.full_messages.join(', ')}"
      end
    end
  end

  describe 'プラン数' do
    it 'Plan は 4 件存在する' do
      expect(Plan.count).to eq 4
    end
  end

  describe '参照整合性' do
    it 'すべての Plan#provider_id が Provider に存在する' do
      provider_ids = Provider.all.map(&:id)
      Plan.all.each do |plan|
        expect(provider_ids).to include(plan.provider_id),
                                "Plan##{plan.id} が参照する provider_id=#{plan.provider_id} は存在しない"
      end
    end

    it 'すべての AmpereBasedRate#plan_id が Plan に存在する' do
      plan_ids = Plan.all.map(&:id)
      AmpereBasedRate.all.each do |rate|
        expect(plan_ids).to include(rate.plan_id)
      end
    end

    it 'すべての UsageBasedRate#plan_id が Plan に存在する' do
      plan_ids = Plan.all.map(&:id)
      UsageBasedRate.all.each do |rate|
        expect(plan_ids).to include(rate.plan_id)
      end
    end
  end

  describe '業務的不変条件' do
    it 'metered_only? が true なのは Looopでんきおうちプラン (id=4) のみである' do
      metered_only_ids = Plan.all.select(&:metered_only?).map(&:id)
      expect(metered_only_ids).to eq [4]
    end
  end

  describe 'rate の型保証' do
    it '全レコードの rate が BigDecimal を返す' do
      [AmpereBasedRate, UsageBasedRate].each do |model|
        model.all.each do |record|
          expect(record.rate).to be_a(BigDecimal),
                                 "#{model.name}##{record.id} の rate: #{record.rate.class}"
        end
      end
    end
  end

  describe '料金レンジの連続性' do
    it '各プランの usage_based_rates の最初の段は low=1 から始まる' do
      Plan.all.each do |plan|
        sorted = plan.usage_based_rates.sort_by(&:kilowatt_hour_low)
        next if sorted.empty?

        first_low = sorted.first.kilowatt_hour_low
        expect(first_low).to eq(1), "Plan##{plan.id}: 最初の段の low は 1 のはずが #{first_low}"
      end
    end

    it '各プランの usage_based_rates は段の間に穴も重複もなく連続している' do
      Plan.all.each do |plan|
        sorted = plan.usage_based_rates.sort_by(&:kilowatt_hour_low)
        sorted.each_cons(2) do |prev_seg, next_seg|
          expected = prev_seg.kilowatt_hour_high + 1
          actual = next_seg.kilowatt_hour_low
          expect(actual).to eq(expected),
                            "Plan##{plan.id}: 段の間に穴/重複あり (#{prev_seg.kilowatt_hour_high} → #{actual})"
        end
      end
    end
  end
end
