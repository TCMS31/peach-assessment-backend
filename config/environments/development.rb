# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Caching is off by default. Run `rails dev:cache` to toggle it.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Fail loudly rather than serving a half-migrated schema.
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Evented file watcher; depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
