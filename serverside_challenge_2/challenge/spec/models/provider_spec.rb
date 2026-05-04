# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Provider do
  describe 'バリデーション' do
    it 'name が空だと invalid になる' do
      record = described_class.new(id: 999, name: nil)
      expect(record).not_to be_valid
      expect(record.errors[:name]).to be_present
    end
  end

  describe 'アソシエーション' do
    it 'has_many :plans が引ける' do
      provider = described_class.find(1)
      expect(provider.plans.map(&:id)).to contain_exactly(1, 2)
    end
  end
end
