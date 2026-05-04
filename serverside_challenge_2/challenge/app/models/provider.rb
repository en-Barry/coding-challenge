# frozen_string_literal: true

class Provider < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  has_many :plans

  validates :name, presence: true
end
