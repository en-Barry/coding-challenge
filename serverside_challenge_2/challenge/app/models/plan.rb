# frozen_string_literal: true

class Plan < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  belongs_to :provider
  has_many :ampere_based_rates
  has_many :usage_based_rates

  validates :name, :provider_id, presence: true

  # ampere_based_rates レコードの有無で従量課金のみプランを判定する
  # （フラグを別途持たせるとレコード有無と矛盾し得るため、レコード有無を単一の真実とする）
  def metered_only?
    ampere_based_rates.empty?
  end
end
