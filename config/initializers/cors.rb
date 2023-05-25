# frozen_string_literal: true

# The origin was hardcoded to http://localhost:3000, which happens to be this
# API's own port and is not where any client runs. Native clients do not send an
# Origin header at all, so the rule never fired for the mobile app; an Expo web
# build or any browser tool was simply blocked.
#
# ALLOWED_ORIGINS is a comma-separated list. Unset means "browsers are not a
# supported client for this deployment", which is a safer default than `*`.
allowed_origins = ENV.fetch('ALLOWED_ORIGINS', '').split(',').map(&:strip).reject(&:empty?)

if allowed_origins.any?
  Rails.application.config.middleware.insert_before(0, Rack::Cors) do
    allow do
      origins(*allowed_origins)
      resource '*',
               headers: :any,
               methods: %i[get patch put options head],
               expose: %w[X-Total-Count X-Page X-Per-Page X-Total-Pages]
    end
  end
end
