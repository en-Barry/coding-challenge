# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsageBasedRate do
  describe 'バリデーション' do
    it 'plan_id / kilowatt_hour_low / kilowatt_hour_high / rate が空だと invalid になる' do
      record = described_class.new(id: 999)
      expect(record).not_to be_valid
      expect(record.errors[:plan_id]).to be_present
      expect(record.errors[:kilowatt_hour_low]).to be_present
      expect(record.errors[:kilowatt_hour_high]).to be_present
      expect(record.errors[:rate]).to be_present
    end

    it 'kilowatt_hour_low が kilowatt_hour_high を超えると invalid になる' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 200, kilowatt_hour_high: 100, rate: '10'
      )
      expect(record).not_to be_valid
      expect(record.errors[:kilowatt_hour_low]).to be_present
    end

    it 'low > high のエラーメッセージが日本語で返る' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 200, kilowatt_hour_high: 100, rate: '10'
      )
      record.valid?
      expect(record.errors[:kilowatt_hour_low]).to include('は kilowatt_hour_high 以下でなければなりません')
    end

    it 'kilowatt_hour_low が 0 以下だと invalid になる' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 0, kilowatt_hour_high: 100, rate: '10'
      )
      expect(record).not_to be_valid
      expect(record.errors[:kilowatt_hour_low]).to be_present
    end

    it 'kilowatt_hour_high が 0 以下だと invalid になる' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 1, kilowatt_hour_high: 0, rate: '10'
      )
      expect(record).not_to be_valid
      expect(record.errors[:kilowatt_hour_high]).to be_present
    end

    it 'rate が数値変換できない文字列だと invalid になる' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 1, kilowatt_hour_high: 100, rate: 'abc'
      )
      expect(record).not_to be_valid
      expect(record.errors[:rate]).to be_present
    end

    it 'rate が負の数だと invalid になる' do
      record = described_class.new(
        id: 999, plan_id: 1, kilowatt_hour_low: 1, kilowatt_hour_high: 100, rate: '-10'
      )
      expect(record).not_to be_valid
      expect(record.errors[:rate]).to be_present
    end
  end

  describe '#rate' do
    it 'BigDecimal を返す' do
      expect(described_class.first.rate).to be_a(BigDecimal)
    end

    it 'YAML の文字列値を BigDecimal として正しく解釈する' do
      expect(described_class.find(1).rate).to eq BigDecimal('19.88')
    end
  end
end
