# frozen_string_literal: true

class Plan < ApplicationRecord
  belongs_to :provider
  has_many :ampere_based_rates, dependent: :destroy
  has_many :usage_based_rates, dependent: :destroy

  validates :name, presence: true

  def metered_only?
    ampere_based_rates.empty?
  end
end
