# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AmpereBasedRate do
  describe 'バリデーション' do
    it 'ampere が許容アンペア数以外だと invalid になる' do
      record = described_class.new(id: 999, plan_id: 1, ampere: 25, rate: '100')
      expect(record).not_to be_valid
      expect(record.errors[:ampere]).to be_present
    end

    it 'plan_id が空だと invalid になる' do
      record = described_class.new(id: 999, plan_id: nil, ampere: 30, rate: '100')
      expect(record).not_to be_valid
      expect(record.errors[:plan_id]).to be_present
    end

    it 'rate が空だと invalid になる' do
      record = described_class.new(id: 999, plan_id: 1, ampere: 30, rate: nil)
      expect(record).not_to be_valid
      expect(record.errors[:rate]).to be_present
    end

    it 'plan_id が 0 以下だと invalid になる' do
      record = described_class.new(id: 999, plan_id: 0, ampere: 30, rate: '100')
      expect(record).not_to be_valid
      expect(record.errors[:plan_id]).to be_present
    end

    it 'rate が数値変換できない文字列だと invalid になる' do
      record = described_class.new(id: 999, plan_id: 1, ampere: 30, rate: 'abc')
      expect(record).not_to be_valid
      expect(record.errors[:rate]).to be_present
    end

    it 'rate が負の数だと invalid になる' do
      record = described_class.new(id: 999, plan_id: 1, ampere: 30, rate: '-100')
      expect(record).not_to be_valid
      expect(record.errors[:rate]).to be_present
    end
  end

  describe '#rate' do
    it 'BigDecimal を返す' do
      record = described_class.new(id: 9999, plan_id: 1, ampere: 30, rate: '100.50')
      expect(record.rate).to be_a(BigDecimal)
    end

    it '文字列を精度を保って BigDecimal に変換する' do
      record = described_class.new(id: 9999, plan_id: 1, ampere: 30, rate: '286.00')
      expect(record.rate).to eq BigDecimal('286.00')
    end
  end
end
