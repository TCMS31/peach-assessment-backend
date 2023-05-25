# Test and lint run

Ruby 3.1.3, Rails 6.1.7.3, PostgreSQL 16.15, RSpec 6.0.

## Suite

```console
$ bundle exec rspec
Randomized with seed 37721
.............................................................................................

Finished in 1.09 seconds (files took 0.65195 seconds to load)
93 examples, 0 failures
```

Coverage by layer:

| Directory                     | What it pins |
| ----------------------------- | ------------ |
| `spec/requests/`              | The wire contract the mobile client reads: exact JSON shapes, status codes, pagination headers, error envelopes, query counts. |
| `spec/controllers/`           | Strong-parameter filtering and delegation to the query and service objects. |
| `spec/queries/`               | Filter casting, contradiction handling, ordering, pagination bounds, preloading, the registry seam. |
| `spec/services/transactions/` | The review use case, including the category-duplication regression. |
| `spec/models/`                | Validations, associations, decimal precision, scopes. |
| `spec/seeds_spec.rb`          | The imported ledger against an independently calculated table (see `seeded-figures.md`). |

From a database that does not exist yet, which is the state a reviewer starts
from:

```console
$ bin/rails db:prepare RAILS_ENV=test
Created database 'peachtakehomebackend_test'

$ bundle exec rspec
93 examples, 0 failures
```

`db:prepare` seeds a database it has just created, so the test database arrives
holding the fixture ledger. `spec/support/test_database.rb` truncates once
before the suite; without it the second run of `rspec` behaves differently from
the first, which is how order-dependent suites start.

## Lint

```console
$ bundle exec rubocop
54 files inspected, no offenses detected
```

## Autoload check

```console
$ bundle exec rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

## Proof the suite can fail

A suite that cannot fail proves nothing. Removing the two lines in
`Transactions::Review#find_or_create_category_by_name` that look up an existing
category - reintroducing the original "create a new category on every review"
behaviour - produces:

```console
$ bundle exec rspec spec/services spec/requests/transactions_spec.rb
30 examples, 6 failures

Failed examples:

rspec ./spec/services/transactions/review_spec.rb:50 # ... resolves an existing category instead of creating a duplicate
rspec ./spec/services/transactions/review_spec.rb:59 # ... matches case-insensitively
rspec ./spec/services/transactions/review_spec.rb:67 # ... stays idempotent when the client sends the same review twice
rspec ./spec/services/transactions/review_spec.rb:75 # ... still allows a genuinely new category name, exactly once
rspec ./spec/services/transactions/review_spec.rb:93 # ... applies the flag and the category in one write
rspec ./spec/requests/transactions_spec.rb:152 # ... recategorises by nested attributes without duplicating the category
```

The mutation was reverted immediately; the committed tree is the passing one
above.

## Starting point, for comparison

On a clean checkout before this pass, **zero examples ran**. `db/schema.rb` was
stamped `2023_06_23_012647` while the migration on disk is
`20230627012647_create_transactions.rb`, so:

```console
$ bin/rails db:prepare RAILS_ENV=test
Created database 'peachtakehomebackend_test'

$ bundle exec rspec
Migrations are pending. To resolve this issue, run:

        bin/rails db:migrate RAILS_ENV=test

You have 1 pending migration:

20230627012647_create_transactions.rb
...
0 examples, 0 failures, 6 errors occurred outside of examples

$ bin/rails db:migrate RAILS_ENV=test
== 20230627012647 CreateTransactions: migrating ===============================
-- create_table(:transactions)
rails aborted!
StandardError: An error has occurred, this and all later migrations canceled:

PG::DuplicateTable: ERROR:  relation "transactions" already exists
```

`db:prepare` loads the schema, RSpec then refuses because the migration is
"pending", and `db:migrate` cannot run because the schema load already created
the table. Regenerating `db/schema.rb` from the migrations broke the deadlock;
the 15 pre-existing examples then passed, and the suite is 93 now.
