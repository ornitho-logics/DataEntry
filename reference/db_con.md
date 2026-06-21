# Create a MariaDB connection

Creates a MariaDB connection from an option file.

## Usage

``` r
db_con(.cnf = NULL, group = NULL)
```

## Arguments

- .cnf:

  Path to a MariaDB option file. If `NULL`, resolved from `cnf_path` or
  `DATAENTRY_CNF`.

- group:

  Option group in `.cnf`. If `NULL`, resolved from global `group` or
  `"DataEntry"`.

## Value

A MariaDB connection.

## Details

If `.cnf` is `NULL`, `db_con()` first looks for `cnf_path` in the global
environment, then for the `DATAENTRY_CNF` environment variable.

If `group` is `NULL`, `db_con()` first looks for `group` in the global
environment, then uses `"DataEntry"`.

Once the environment variable is set, this lets app-level `global.R`
files set only:

    group = "DataEntry"
