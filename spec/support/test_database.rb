# frozen_string_literal: true

# Empties the test database once, before the suite runs.
#
# `database_cleaner` used to be a dependency for exactly this; it is not needed.
# Each example runs inside a transaction that is rolled back, so the only thing
# that has to be cleared is whatever existed before the first example - which,
# after `rails db:prepare` on a fresh database, is the seeded fixture ledger.
module TestDatabase
  PRESERVED_TABLES = %w[schema_migrations ar_internal_metadata].freeze

  module_function

  def truncate!
    connection = ActiveRecord::Base.connection
    tables = connection.tables - PRESERVED_TABLES
    return if tables.empty?

    quoted = tables.map { |table| connection.quote_table_name(table) }.join(', ')
    connection.execute("TRUNCATE TABLE #{quoted} RESTART IDENTITY CASCADE")
  end
end
