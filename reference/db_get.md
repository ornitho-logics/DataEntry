# Run a MariaDB query and return a data.table

Run a MariaDB query and return a data.table

## Usage

``` r
db_get(query, ..., params = NULL)
```

## Arguments

- query:

  SQL query passed to
  [`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html).

- ...:

  Additional arguments passed to
  [`db_con()`](https://mpio-be.github.io/DataEntry/reference/db_con.md).

- params:

  Optional query parameters passed to
  [`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html).

## Value

A data.table.

## Details

Read connections are reused within a Shiny session and closed when it
ends. Reads outside a Shiny session close their connection after each
call. Failed queries discard the connection and are not retried
automatically.
