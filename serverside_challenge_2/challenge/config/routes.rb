# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :electricity_bill_simulations, only: [:index]
    end
  end
end
