# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'YAMLデータ整合性' do
  [Provider, Plan, AmpereBasedRate, UsageBasedRate].each do |model|
    it "#{model.name} の全レコードが valid であること" do
      model.all.each do |record|
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
end
