# Captured API session

Real output from a `rails s` process on `127.0.0.1:8820` against a database
seeded with `rails db:seed` (`RAILS_ENV=development`, Ruby 3.1.3, Rails 6.1.7.3,
PostgreSQL 16.15). `X-Request-Id`, `X-Runtime`, `ETag` and `Date` headers are
stripped so the transcript is stable between runs; nothing else is edited.

Reproduce with:

```bash
bin/rails db:prepare db:seed
PORT=8820 bin/rails s -b 127.0.0.1 -p 8820
```

---

## Health probe

```console
$ curl -s -i http://127.0.0.1:8820/health
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"status":"ok","database":"ok"}
```

## Reference data

```console
$ curl -s -i http://127.0.0.1:8820/categories
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

[{"id":2,"name":"Food and Drink","emoji":"🍕","color":"#FFC9C9","budget":null},
 {"id":3,"name":"Healthcare","emoji":"🏥","color":"#E5CBAF","budget":null},
 {"id":1,"name":"Income","emoji":"🤑","color":"#DDF1A3","budget":null},
 {"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null},
 {"id":5,"name":"Subscription Service","emoji":"📺","color":"#FFDAF9","budget":null},
 {"id":7,"name":"Taxes","emoji":"💸","color":"#C5C8FF","budget":null},
 {"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}]
```

(The array is returned on one line; it is wrapped here for readability. Every
other body below is byte-for-byte as received.)

```console
$ curl -s -i http://127.0.0.1:8820/merchants
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

[{"id":5,"name":"Amazon"},{"id":8,"name":"AMC"},{"id":7,"name":"Blue Cross"},{"id":3,"name":"Chipotle"},{"id":10,"name":"Hulu"},{"id":9,"name":"Netflix"},{"id":4,"name":"Payroll"},{"id":6,"name":"Turbo Tax"},{"id":1,"name":"Uber"},{"id":2,"name":"United"}]
```

## Listing transactions, filtered and paged

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?pending_review=true&per_page=2'
HTTP/1.1 200 OK
X-Total-Count: 10
X-Page: 1
X-Per-Page: 2
X-Total-Pages: 5
Content-Type: application/json; charset=utf-8

[{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":false,"merchant":{"id":2,"name":"United"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}},{"id":1,"name":"Uber","date":"2023-05-29","amount":"45.12","reviewed":false,"merchant":{"id":1,"name":"Uber"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}}]
```

The body is a bare array; pagination is in headers. The mobile client feeds this
response straight into `normalizeTransactions`, which returns `[]` for anything
that is not an array, so an envelope would blank the screen.

## Fetching one transaction

```console
$ curl -s -i http://127.0.0.1:8820/transactions/2
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":false,"merchant":{"id":2,"name":"United"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}}
```

## Reviewing and recategorising

This is the write the mobile app performs. Before the fix, the same call created
a *new* category row named "Travel" with `color: null`.

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 \
    -H 'Content-Type: application/json' \
    -d '{"transaction":{"reviewed":true,"category_attributes":{"name":"Travel","emoji":"✈️"}}}'
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":true,"merchant":{"id":2,"name":"United"},"category":{"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}}
```

The transaction now points at the existing category 6, with its colour intact,
and `GET /categories` still returns exactly seven rows.

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?reviewed=true'
HTTP/1.1 200 OK
X-Total-Count: 1
X-Page: 1
X-Per-Page: 100
X-Total-Pages: 1
Content-Type: application/json; charset=utf-8

[{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":true,"merchant":{"id":2,"name":"United"},"category":{"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}}]
```

## Errors

All four share one envelope: `{"message": [...]}`, always an array.

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?reviewed=maybe'
HTTP/1.1 400 Bad Request
Content-Type: application/json; charset=utf-8

{"message":["reviewed must be true or false"]}
```

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 \
    -H 'Content-Type: application/json' -d '{"transaction":{"category_id":999999}}'
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json; charset=utf-8

{"message":["Category 999999 does not exist"]}
```

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 -d 'reviewed=true'
HTTP/1.1 400 Bad Request
Content-Type: application/json; charset=utf-8

{"message":["Missing required parameter: transaction"]}
```

```console
$ curl -s -i http://127.0.0.1:8820/transactions/999999
HTTP/1.1 404 Not Found
Content-Type: application/json; charset=utf-8

{"message":["Transaction not found"]}
```

Note: a JSON body without the `transaction` key is *not* an error, because
`config/initializers/wrap_parameters.rb` wraps a bare JSON object into
`params[:transaction]`. The 400 above is a form-encoded request, where no
wrapping happens.

## Query count

Measured with `ActiveSupport::Notifications` on the seeded database
(10 transactions), serialising through `TransactionSerializer`:

```console
$ bin/rails runner scripts/bench_queries.rb
rows in table:        10
queries, old code:    21
queries, new code:    3
```

21 is `1 + 2N`: one for the list, then a category and a merchant lookup per row.
3 is the list plus one preload per association. The `GET /transactions` endpoint
issues a fourth for the `X-Total-Count` header.
