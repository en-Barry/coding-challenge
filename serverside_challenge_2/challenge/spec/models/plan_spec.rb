# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plan do
  describe 'バリデーション' do
    it 'name が空だと invalid になる' do
      record = described_class.new(id: 999, name: nil, provider_id: 1)
      expect(record).not_to be_valid
      expect(record.errors[:name]).to be_present
    end

    it 'provider_id が空だと invalid になる' do
      record = described_class.new(id: 999, name: 'foo', provider_id: nil)
      expect(record).not_to be_valid
      expect(record.errors[:provider_id]).to be_present
    end

    it 'provider_id が 0 以下だと invalid になる' do
      record = described_class.new(id: 999, name: 'foo', provider_id: 0)
      expect(record).not_to be_valid
      expect(record.errors[:provider_id]).to be_present
    end

    it 'provider_id が文字列だと invalid になる' do
      record = described_class.new(id: 999, name: 'foo', provider_id: 'abc')
      expect(record).not_to be_valid
      expect(record.errors[:provider_id]).to be_present
    end
  end

  describe 'アソシエーション' do
    it 'belongs_to :provider が Provider を返す' do
      plan = described_class.all.find { |p| p.provider_id.present? }
      expect(plan.provider).to be_a(Provider)
    end

    it 'has_many :ampere_based_rates が AmpereBasedRate の配列を返す' do
      plan = described_class.all.find { |p| p.ampere_based_rates.any? }
      expect(plan.ampere_based_rates).to all(be_a(AmpereBasedRate))
    end

    it 'has_many :usage_based_rates が UsageBasedRate の配列を返す' do
      plan = described_class.all.find { |p| p.usage_based_rates.any? }
      expect(plan.usage_based_rates).to all(be_a(UsageBasedRate))
    end
  end

  describe '#metered_only?' do
    it 'ampere_based_rates が存在しないプランは true を返す' do
      plan = described_class.new(id: 9999, name: 'テスト', provider_id: 1)
      expect(plan.metered_only?).to be true
    end

    it 'ampere_based_rates が存在するプランは false を返す' do
      plan = described_class.all.find { |p| p.ampere_based_rates.any? }
      expect(plan.metered_only?).to be false
    end
  end
end
