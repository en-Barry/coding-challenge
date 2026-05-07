# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plan do
  describe 'バリデーション' do
    it 'name が空だと invalid になる' do
      record = build(:plan, name: nil)
      expect(record).not_to be_valid
      expect(record.errors[:name]).to be_present
    end

    it 'provider が nil だと invalid になる' do
      record = build(:plan, provider: nil)
      expect(record).not_to be_valid
      expect(record.errors[:provider]).to be_present
    end
  end

  describe 'アソシエーション' do
    let(:plan) { create(:plan) }

    it 'belongs_to :provider が引ける' do
      expect(plan.provider).to be_a(Provider)
    end

    it 'has_many :ampere_based_rates が引ける' do
      create_list(:ampere_based_rate, 3, plan: plan)
      expect(plan.ampere_based_rates.size).to eq 3
    end

    it 'has_many :usage_based_rates が引ける' do
      create_list(:usage_based_rate, 2, plan: plan)
      expect(plan.usage_based_rates.size).to eq 2
    end
  end

  describe '#metered_only?' do
    it 'ampere_based_rates が存在しない場合に true を返す' do
      plan = create(:plan)
      expect(plan.metered_only?).to be true
    end

    it 'ampere_based_rates が存在する場合は false を返す' do
      plan = create(:plan)
      create(:ampere_based_rate, plan: plan)
      expect(plan.metered_only?).to be false
    end
  end
end
