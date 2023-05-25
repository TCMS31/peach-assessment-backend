# frozen_string_literal: true

# Counts the SQL queries needed to serialise the transaction list, the way the
# original controller did it (`Transaction.all`) and the way TransactionsQuery
# does it now. Run against a seeded database:
#
#   bin/rails runner scripts/bench_queries.rb
#
# The numbers quoted in docs/api-transcript.md came from this script.

def count_queries
  count = 0
  subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
    count += 1 unless %w[SCHEMA TRANSACTION CACHE].include?(payload[:name])
  end
  yield
  ActiveSupport::Notifications.unsubscribe(subscription)
  count
end

def serialize(relation)
  ActiveModelSerializers::SerializableResource
    .new(relation, each_serializer: TransactionSerializer)
    .to_json
end

Transaction.connection.query_cache.clear
before = count_queries { serialize(Transaction.all) }

Transaction.connection.query_cache.clear
after = count_queries { serialize(TransactionsQuery.new({}).results) }

puts "rows in table:        #{Transaction.count}"
puts "queries, old code:    #{before}"
puts "queries, new code:    #{after}"
