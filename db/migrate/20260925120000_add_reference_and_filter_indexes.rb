# frozen_string_literal: true

# Two problems this closes.
#
# 1. Nothing stopped a duplicate "Travel" category. The PATCH endpoint used to
#    create one on every recategorisation, so duplicates were not hypothetical.
#    Names are matched case-insensitively, so the constraint is on LOWER(name).
# 2. `GET /transactions?pending_review=true` filtered on `reviewed` and ordered
#    by `date` with no index on either, so every request was a sequential scan
#    plus a sort. The composite index serves the filter and the ordering.
class AddReferenceAndFilterIndexes < ActiveRecord::Migration[6.1]
  def up
    deduplicate!(:categories)
    deduplicate!(:merchants)

    execute 'CREATE UNIQUE INDEX index_categories_on_lower_name ON categories (LOWER(name))'
    execute 'CREATE UNIQUE INDEX index_merchants_on_lower_name ON merchants (LOWER(name))'

    add_index :transactions, %i[reviewed date], order: { date: :desc }
    add_index :transactions, :date, order: { date: :desc }
  end

  def down
    remove_index :transactions, column: :date
    remove_index :transactions, column: %i[reviewed date]
    execute 'DROP INDEX IF EXISTS index_merchants_on_lower_name'
    execute 'DROP INDEX IF EXISTS index_categories_on_lower_name'
  end

  private

  # Repoints transactions at the lowest-id row for each name before the unique
  # index goes on, so an existing database corrupted by the old PATCH endpoint
  # migrates instead of failing.
  def deduplicate!(table)
    execute(<<~SQL.squish)
      UPDATE transactions t
         SET #{table.to_s.singularize}_id = canonical.keep_id
        FROM (
              SELECT id, MIN(id) OVER (PARTITION BY LOWER(name)) AS keep_id
                FROM #{table}
             ) canonical
       WHERE t.#{table.to_s.singularize}_id = canonical.id
         AND canonical.id <> canonical.keep_id
    SQL

    execute(<<~SQL.squish)
      DELETE FROM #{table}
       WHERE id NOT IN (SELECT MIN(id) FROM #{table} GROUP BY LOWER(name))
    SQL
  end
end
