# Create a MariaDB connection

Uses credentials from the global environment by default.

## Usage

``` r
db_con(.cnf = get("cnf_path", envir = .GlobalEnv))
```

## Arguments

- host:

  Database host.

- user:

  Database user.

- pwd:

  Database password.

- db:

  Database name.

## Value

A MariaDB connection.
