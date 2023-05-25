# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

# The generated file left this commented out, so spec/support/*.rb was never
# loaded and the shoulda-matchers include in it never took effect.
Rails.root.glob('spec/support/**/*.rb').sort.each { |file| require file }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]
  config.use_transactional_fixtures = true

  # `rails db:prepare` seeds a database it has just created, so the test
  # database can arrive holding the whole fixture ledger. Specs assert on counts
  # and on unique category names, so the suite starts from empty regardless of
  # how the database was set up.
  config.before(:suite) { TestDatabase.truncate! }
  config.include FactoryBot::Syntax::Methods
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
