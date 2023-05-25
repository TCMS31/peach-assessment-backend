# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

# The test environment is used exclusively to run the test suite. The test
# database is scratch space: it is wiped and recreated between runs.
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise instead of rendering an error document, so a 500 shows up as a
  # failure with a backtrace rather than as a passing "returns a response".
  config.action_dispatch.show_exceptions = :none

  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
end
