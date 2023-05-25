# Seeded figures

The fixture ledger is `transactions.csv`. This page records what it *should*
add up to, computed independently of the application, and what the database
actually holds after `rails db:seed`. The same table is asserted in
`spec/seeds_spec.rb`, so an import regression fails the suite.

## The fixture, row by row

| Transaction Name | Merchant   | Amount    | Date       | Category |
| ---------------- | ---------- | --------- | ---------- | -------- |
| Uber             | Uber       | 45.12     | 2023-05-29 | Shops    |
| SFO to JFK       | United     | 129.97    | 2023-05-29 | Shops    |
| Hulu             | Hulu       | 6.99      | 2023-05-28 | Shops    |
| Chipotle         | Chipotle   | 12.88     | 2023-05-28 | Shops    |
| Direct Deposit   | Payroll    | -2100.54  | 2023-05-28 | Shops    |
| Amazon           | Amazon     | 70.24     | 2023-05-27 | Shops    |
| Taxes 2022       | Turbo Tax  | 110.00    | 2023-05-27 | Shops    |
| Dr. Seuss        | Blue Cross | 55.23     | 2023-05-27 | Shops    |
| Fast X           | AMC        | 25.99     | 2023-05-26 | Shops    |
| Netflix          | Netflix    | 9.99      | 2023-05-25 | Shops    |

Positive is money out, negative is money in.

**The fixture files all ten rows under "Shops"** - a payroll deposit and a tax
payment included. That is how the take-home ships it, and it is the point of the
product: the ledger arrives miscategorised and a person corrects it. The
importer reproduces the CSV faithfully rather than guessing better categories,
and `spec/seeds_spec.rb` asserts that it does.

## Expected totals, computed from the CSV with exact decimals

```console
$ python3 - <<'PY'
from decimal import Decimal
import csv
rows = [{k.strip(): v.strip() for k, v in r.items() if k}
        for r in csv.DictReader(open('transactions.csv'))]
net = sum((Decimal(r['Amount']) for r in rows), Decimal(0))
out = sum((Decimal(r['Amount']) for r in rows if Decimal(r['Amount']) > 0), Decimal(0))
inn = sum((Decimal(r['Amount']) for r in rows if Decimal(r['Amount']) < 0), Decimal(0))
print('rows  ', len(rows)); print('net   ', net); print('out   ', out); print('in    ', inn)
PY
rows   10
net    -1634.13
out    466.41
in     -2100.54
```

## What the database holds after seeding

```console
$ bin/rails db:drop db:create db:schema:load db:seed
$ psql -At peachtakehomebackend_development \
    -c "SELECT c.name||'|'||count(*)||'|'||to_char(sum(t.amount),'FM999990.00')
          FROM transactions t JOIN categories c ON c.id = t.category_id
         GROUP BY c.name ORDER BY c.name;"
Shops|10|-1634.13

$ psql -At peachtakehomebackend_development \
    -c "SELECT to_char(sum(amount),'FM999990.00') FROM transactions;" \
    -c "SELECT to_char(sum(amount),'FM999990.00') FROM transactions WHERE amount > 0;" \
    -c "SELECT to_char(sum(amount),'FM999990.00') FROM transactions WHERE amount < 0;"
-1634.13
466.41
-2100.54
```

Identical to the independent calculation, to the cent. `amount` is
`decimal(22, 3)` and is serialised to JSON as a string, so no value passes
through an IEEE-754 double on the way to the client.
