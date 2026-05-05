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
    let(:plan) { described_class.find(1) }

    it 'belongs_to :provider が引ける' do
      expect(plan.provider.name).to eq '東京電力エナジーパートナー'
    end

    it 'has_many :ampere_based_rates が引ける' do
      expect(plan.ampere_based_rates.size).to eq 7
    end

    it 'has_many :usage_based_rates が引ける' do
      expect(plan.usage_based_rates.size).to eq 3
    end
  end

  describe '#metered_only?' do
    it 'Looopでんきおうちプラン (id=4) のみ true を返す' do
      expect(described_class.find(4).metered_only?).to be true
      expect(described_class.find(1).metered_only?).to be false
      expect(described_class.find(2).metered_only?).to be false
      expect(described_class.find(3).metered_only?).to be false
    end
  end
end
