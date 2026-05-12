# frozen_string_literal: true

class HealthzController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok' }, status: :ok
  rescue StandardError => e
    Rails.logger.warn("Healthz DB check failed: #{e.class}: #{e.message}")
    render json: { status: 'error' }, status: :service_unavailable
  end
end
