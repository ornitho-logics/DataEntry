# Data entry server modules

Server modules for appending rows, editing database tables, and editing
inspector definitions.

## Usage

``` r
server_append_rows(input, output, session)

server_edit_rcode(input, output, session)

server_edit_table(input, output, session)
```

## Arguments

- input:

  Shiny input object.

- output:

  Shiny output object.

- session:

  Shiny session object.

## Value

Called for side effects.

Called for side effects.

## Note

See `global.R` in `inst/UI/newData` for required variables to set.

See `global.R` in `inst/UI/editInspector` for required variables to set.

See `global.R` in `inst/UI/editData` for required variables to set.
