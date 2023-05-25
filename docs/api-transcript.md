# Captured API session

Real output from the committed `docker-compose.yml` (Ruby 3.4.12, Rails 8.1.4.1,
`postgres:16-alpine`), started from a clean checkout with
`docker compose up --build`. `db:prepare` created the schema and seeded the
fixture ledger on first boot. Only the status line, `content-type` and the
pagination headers are kept; `x-request-id`, `x-runtime`, `etag`, `date` and
the cache headers are stripped so the transcript is stable between runs.
Rack 3 sends header names in lower case.

The session ran with `API_PORT=18820` to stay clear of other local services;
the commands are shown against 8820, the Compose default.

---

## Health probe

```console
$ curl -s -i http://127.0.0.1:8820/health
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

{"status":"ok","database":"ok"}
```

## Reference data

Both lists are ordered by `LOWER(name)`, so "Amazon" sorts before "AMC" on any
database collation.

```console
$ curl -s -i http://127.0.0.1:8820/categories
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

[{"id":2,"name":"Food and Drink","emoji":"🍕","color":"#FFC9C9","budget":null},{"id":3,"name":"Healthcare","emoji":"🏥","color":"#E5CBAF","budget":null},{"id":1,"name":"Income","emoji":"🤑","color":"#DDF1A3","budget":null},{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null},{"id":5,"name":"Subscription Service","emoji":"📺","color":"#FFDAF9","budget":null},{"id":7,"name":"Taxes","emoji":"💸","color":"#C5C8FF","budget":null},{"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}]
```

```console
$ curl -s -i http://127.0.0.1:8820/merchants
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

[{"id":5,"name":"Amazon"},{"id":8,"name":"AMC"},{"id":7,"name":"Blue Cross"},{"id":3,"name":"Chipotle"},{"id":10,"name":"Hulu"},{"id":9,"name":"Netflix"},{"id":4,"name":"Payroll"},{"id":6,"name":"Turbo Tax"},{"id":1,"name":"Uber"},{"id":2,"name":"United"}]
```

## Listing transactions, filtered and paged

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?pending_review=true&per_page=2'
HTTP/1.1 200 OK
x-total-count: 10
x-page: 1
x-per-page: 2
x-total-pages: 5
content-type: application/json; charset=utf-8

[{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":false,"merchant":{"id":2,"name":"United"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}},{"id":1,"name":"Uber","date":"2023-05-29","amount":"45.12","reviewed":false,"merchant":{"id":1,"name":"Uber"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}}]
```

The body is a bare array; pagination is in headers. The mobile client feeds this
response straight into `normalizeTransactions`, which returns `[]` for anything
that is not an array, so an envelope would blank the screen.

## Fetching one transaction

```console
$ curl -s -i http://127.0.0.1:8820/transactions/2
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":false,"merchant":{"id":2,"name":"United"},"category":{"id":4,"name":"Shops","emoji":"🛍","color":"#B6E4FB","budget":null}}
```

## Reviewing and recategorising

This is the write the mobile app performs. Before the fix, the same call created
a *new* category row named "Travel" with `color: null`.

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 -H 'Content-Type: application/json' -d '{"transaction":{"reviewed":true,"category_attributes":{"name":"Travel","emoji":"✈️"}}}'
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8

{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":true,"merchant":{"id":2,"name":"United"},"category":{"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}}
```

The transaction now points at the existing category 6, with its colour intact,
and the category list still has exactly seven rows:

```console
$ curl -s http://127.0.0.1:8820/categories | grep -o '"id"' | wc -l
       7
```

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?reviewed=true'
HTTP/1.1 200 OK
x-total-count: 1
x-page: 1
x-per-page: 100
x-total-pages: 1
content-type: application/json; charset=utf-8

[{"id":2,"name":"SFO to JFK","date":"2023-05-29","amount":"129.97","reviewed":true,"merchant":{"id":2,"name":"United"},"category":{"id":6,"name":"Travel","emoji":"✈️","color":"#FFECC6","budget":null}}]
```

## Errors

All of them share one envelope: `{"message": [...]}`, always an array.

A filter value the server cannot read, or two filters that contradict each
other, is a 400 rather than a guess:

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?reviewed=maybe'
HTTP/1.1 400 Bad Request
content-type: application/json; charset=utf-8

{"message":["reviewed must be true or false"]}
```

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?reviewed=true&pending_review=true'
HTTP/1.1 400 Bad Request
content-type: application/json; charset=utf-8

{"message":["reviewed and pending_review contradict each other"]}
```

A page number past what Postgres can use as an `OFFSET` is a 400, with no
pagination headers:

```console
$ curl -s -i 'http://127.0.0.1:8820/transactions?page=99999999999999999999'
HTTP/1.1 400 Bad Request
content-type: application/json; charset=utf-8

{"message":["page is out of range"]}
```

The review write is just as strict about its flag, and about the category it is
pointed at:

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/3 -H 'Content-Type: application/json' -d '{"transaction":{"reviewed":"maybe"}}'
HTTP/1.1 422 Unprocessable Content
content-type: application/json; charset=utf-8

{"message":["reviewed must be true or false"]}
```

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 -H 'Content-Type: application/json' -d '{"transaction":{"category_id":999999}}'
HTTP/1.1 422 Unprocessable Content
content-type: application/json; charset=utf-8

{"message":["Category 999999 does not exist"]}
```

A `transaction` that is not an object, or a form-encoded body with no
`transaction` key at all, is a 400:

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 -H 'Content-Type: application/json' -d '{"transaction":"reviewed"}'
HTTP/1.1 400 Bad Request
content-type: application/json; charset=utf-8

{"message":["Missing required parameter: transaction"]}
```

```console
$ curl -s -i -X PATCH http://127.0.0.1:8820/transactions/2 -d 'reviewed=true'
HTTP/1.1 400 Bad Request
content-type: application/json; charset=utf-8

{"message":["Missing required parameter: transaction"]}
```

```console
$ curl -s -i http://127.0.0.1:8820/transactions/999999
HTTP/1.1 404 Not Found
content-type: application/json; charset=utf-8

{"message":["Transaction not found"]}
```

Note: a JSON body without the `transaction` key is *not* an error, because
`config/initializers/wrap_parameters.rb` wraps a bare JSON object into
`params[:transaction]`. The form-encoded 400 above is the case where no wrapping
happens.

## Query count

Measured with `ActiveSupport::Notifications` on a database seeded by `bin/setup`
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
