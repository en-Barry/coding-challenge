# frozen_string_literal: true

class Provider < ActiveYaml::Base
  include ActiveHash::Associations
  include ActiveModel::Validations

  fields :name

  has_many :plans

  validates :name, presence: true
end
