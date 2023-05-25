# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.4', '>= 8.1.4.1'

# PostgreSQL is the only supported database: the schema relies on decimal
# precision and foreign keys, and the seed data is imported as decimals.
gem 'pg', '~> 1.6'
gem 'puma', '~> 8.0', '>= 8.0.2'

# Reduces boot times through caching; required in config/boot.rb.
gem 'bootsnap', require: false

# JSON representation layer. Serializers live in app/serializers.
gem 'active_model_serializers', '~> 0.10.16'

# The seed importer parses transactions.csv. csv left Ruby's default gems in 3.4.
gem 'csv', '~> 3.3'

# Browser clients (Expo web, tooling) need CORS; native clients do not send Origin.
gem 'rack-cors', '~> 3.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem.
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop', '~> 1.92', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'listen', '~> 3.10'
end

group :test do
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 8.0'
  gem 'shoulda-matchers', '~> 8.0'
end
