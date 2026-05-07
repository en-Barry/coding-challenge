# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'シードデータの整合性' do
  before { Rails.application.load_seed }

  describe 'プラン数' do
    it 'Plan は 4 件存在する' do
      expect(Plan.count).to eq 4
    end
  end

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
    it 'metered_only? なプランは Looopでんきおうちプラン (id=4) のみ' do
      metered_only = Plan.all.select(&:metered_only?)
      expect(metered_only.map(&:name)).to eq(['おうちプラン'])
    end
  end
end
