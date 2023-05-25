# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Serve /public directly only when there is no reverse proxy in front.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Terminate TLS at the edge, but refuse plaintext unless explicitly allowed
  # (the container image is normally run behind a proxy that already does TLS).
  config.force_ssl = ENV.fetch('RAILS_FORCE_SSL', 'false') == 'true'

  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info').to_sym
  config.log_tags = [:request_id]
  config.log_formatter = Logger::Formatter.new

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.active_support.disallowed_deprecation = :log
  config.active_support.disallowed_deprecation_warnings = []

  # Containers log to stdout; there is no writable log directory in the image.
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
end
