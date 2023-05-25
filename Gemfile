# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1.0'

gem 'rails', '~> 6.1.7', '>= 6.1.7.3'

# PostgreSQL is the only supported database: the schema relies on decimal
# precision and foreign keys, and the seed data is imported as decimals.
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'

# Reduces boot times through caching; required in config/boot.rb.
gem 'bootsnap', '>= 1.4.4', require: false

# JSON representation layer. Serializers live in app/serializers.
gem 'active_model_serializers', '~> 0.10.13'

# Pinned deliberately: json 3.x changes ActiveSupport's JSON encoding paths and
# breaks `render json:` on Rails 6.1. See README > Design notes.
gem 'json', '~> 2.6'

# Browser clients (Expo web, tooling) need CORS; native clients do not send Origin.
gem 'rack-cors'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem.
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'listen', '~> 3.3'
end

group :test do
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 6.0'
  gem 'shoulda-matchers', '~> 5.0'
end
