# Test and lint run

Ruby 3.4.12, Rails 8.1.4.1, PostgreSQL 16 (`postgres:16-alpine`), RSpec 3.13 with
rspec-rails 8.1. Every command below ran inside Docker; the test container sat on
an internal network with only the database reachable.

## Suite

```console
$ bin/rails db:prepare RAILS_ENV=test
Created database 'peachtakehomebackend_test'

$ bundle exec rspec
Randomized with seed 33102
.....................................................................................................................

Finished in 2.75 seconds (files took 0.8116 seconds to load)
117 examples, 0 failures
```

`db:prepare` seeds a database it has just created, so the test database arrives
holding the fixture ledger. `spec/support/test_database.rb` truncates once
before the suite; without it the second run of `rspec` behaves differently from
the first, which is how order-dependent suites start.

Coverage by layer:

| Path                          | What it pins |
| ----------------------------- | ------------ |
| `spec/requests/`              | The wire contract the mobile client reads: exact JSON shapes, status codes, pagination headers, error envelopes, query counts. |
| `spec/controllers/`           | Strong-parameter filtering and delegation to the query and service objects. |
| `spec/queries/`               | Filter casting, contradiction handling, ordering, pagination bounds, preloading, the registry seam. |
| `spec/services/`              | The review use case (including the category-duplication regression) and `StrictBoolean`. |
| `spec/models/`                | Validations, associations, decimal precision, scopes, collation-independent ordering. |
| `spec/seeds_spec.rb`          | The imported fixture against an independently calculated table (see `seeded-figures.md`). |
| `spec/seeds_import_spec.rb`   | The importer against other CSVs: BOM, blank lines, case, duplicate rows, malformed amounts and dates. |

## Lint

```console
$ bundle exec rubocop
57 files inspected, no offenses detected
```

## Autoload check

```console
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

The production image runs the same check during `docker build`.

## Dependency audit

```console
$ bundle-audit check --update
No vulnerabilities found
```

(bundler-audit was installed in a throwaway container; it is not in the
Gemfile.) The Rails 6.1.7.3 lock this replaced reported 170 advisories,
among them a Strong Parameters bypass in Action Pack that is fixed only in
8.0.5.2 / 8.1.4.1.

## Proof the suite can fail

A suite that cannot fail proves nothing. Removing the two lines in
`Transactions::Review#find_or_create_category_by_name` that look up an existing
category - reintroducing the original "create a new category on every review"
behaviour - produces:

```console
$ bundle exec rspec spec/services spec/requests/transactions_spec.rb
39 examples, 6 failures

Failed examples:

rspec ./spec/requests/transactions_spec.rb:168 # ... recategorises by nested attributes without duplicating the category
rspec ./spec/services/transactions/review_spec.rb:106 # ... applies the flag and the category in one write
rspec ./spec/services/transactions/review_spec.rb:80 # ... stays idempotent when the client sends the same review twice
rspec ./spec/services/transactions/review_spec.rb:72 # ... matches case-insensitively
rspec ./spec/services/transactions/review_spec.rb:88 # ... still allows a genuinely new category name, exactly once
rspec ./spec/services/transactions/review_spec.rb:63 # ... resolves an existing category instead of creating a duplicate
```

Likewise, deleting the `MAX_OFFSET` guard in `TransactionsQuery#offset` turns
`?page=99999999999999999999` back into
`PG::NumericValueOutOfRange: value "9999999999999999999800" is out of range for type bigint`.
Both mutations were made in a throwaway copy; the committed tree is the passing
one above.

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
the 15 pre-existing examples then passed. That pass grew the suite to 93
examples; the Rails 8.1 pass took it to 117.
