# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# This is a JSON API: only the railties an API needs are loaded. The generated
# app used `require "rails/all"`, which also booted Action Mailer, Action Cable,
# Active Storage, Action Mailbox and Action Text - none of which this service
# has ever used, all of which cost boot time and memory.
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Peachtakehomebackend
  # Rails application configuration for the Peach transactions API.
  class Application < Rails::Application
    config.load_defaults 6.1

    # No cookies, no sessions, no flash and no view layer on the request path.
    config.api_only = true

    # Autoload the query and service layers alongside the default app/* dirs.
    config.paths.add 'app/queries', eager_load: true
    config.paths.add 'app/services', eager_load: true

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.helper false
      g.assets false
    end
  end
end
