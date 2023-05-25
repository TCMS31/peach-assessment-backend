# frozen_string_literal: true

# Liveness/readiness probe for the container healthcheck and any load balancer.
#
# It touches the database on purpose: an app process that has booted but cannot
# reach Postgres is not healthy, and a probe that only proves Puma is listening
# is the reason "green dashboard, 500s everywhere" happens.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.with_connection { |connection| connection.execute('SELECT 1') }
    render json: { status: 'ok', database: 'ok' }, status: :ok
  rescue StandardError => e
    Rails.logger.error("health check failed: #{e.class}: #{e.message}")
    render json: { status: 'error', database: 'unavailable' }, status: :service_unavailable
  end
end
