# frozen_string_literal: true

class AmpereBasedRate < ApplicationRecord
  belongs_to :plan

  validates :ampere, presence: true, inclusion: { in: [10, 15, 20, 30, 40, 50, 60] }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
