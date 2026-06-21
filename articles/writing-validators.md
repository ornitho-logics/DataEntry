# Writing validators

``` r

library(DataEntry)
library(data.table)
```

Validators are small R functions that find entries which should not be
saved without review.

A validator can use any data-crunching framework you prefer:
`data.table`, `dplyr`, base R, or something else. The only contract is
the return value.

A validator returns a `data.frame`, `data.table`, or similar object
containing at least these columns:

| Column     | Meaning                                  |
|------------|------------------------------------------|
| `rowid`    | Row number in the table being validated. |
| `variable` | Column name that failed validation.      |
| `reason`   | Message shown to the data-entry user.    |

Extra columns are ignored. The validation display uses `rowid`,
`variable`, and `reason`.

If there are no problems, return zero rows with the same column names.

## Start With A Local Table

When a validator runs inside `DataEntry`, the current table is available
as **`x`**.

When developing validators locally, start from the table you want to
validate which you can load from the database. Then use a small subset
that contains the columns and rows needed by the rule.

``` r

x <- data.table(
  species = c("BADO", "WRYB", NA, "SNZD"),
  site = c("AR", "ZZ", "CH", "CR"),
  date = c("2026-06-01", "2026-06-02", "2026-06-03", "2026-06-04"),
  caught = c("10:05", "12:20", "09:15", "16:40"),
  released = c("10:20", "12:10", "09:45", "17:00"),
  nest_id = c("BA01001", "BA99001", "BA02042", "BA21010"),
  observer = c("MV", "AB", "XX", "MV"),
  ring = c("CP12345", "C123", "CP54321", NA),
  capture_status = c("F", "F", "R", "F"),
  age = c("A", "A", "J", "A"),
  tag_type = c("PTT", "GPS", NA, "PTT"),
  tag_id = c(266380, 24, NA, 266500),
  UL = c("FWAC", "X", "FWCE", "FWAC"),
  LL = c("R", "B", "G", "R"),
  UR = c("X", "FWUV", "X", "X"),
  LR = c("W", "Y", "B", "W"),
  rowid = 1:4
)

x
```

| species | site | date | caught | released | nest_id | observer | ring | capture_status | age | tag_type | tag_id | UL | LL | UR | LR | rowid |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|---:|:---|:---|:---|:---|---:|
| BADO | AR | 2026-06-01 | 10:05 | 10:20 | BA01001 | MV | CP12345 | F | A | PTT | 266380 | FWAC | R | X | W | 1 |
| WRYB | ZZ | 2026-06-02 | 12:20 | 12:10 | BA99001 | AB | C123 | F | A | GPS | 24 | X | B | FWUV | Y | 2 |
| NA | CH | 2026-06-03 | 09:15 | 09:45 | BA02042 | XX | CP54321 | R | J | NA | NA | FWCE | G | X | B | 3 |
| SNZD | CR | 2026-06-04 | 16:40 | 17:00 | BA21010 | MV | NA | F | A | PTT | 266500 | FWAC | R | X | W | 4 |

Keep `rowid` when you subset rows. Built-in validators can add `rowid`
to simple tables, but custom validators should preserve the link back to
the original table row.

## A Simple Validator

You can use any validator that is shipped with the package.

This code is a validator because it returns `rowid`, `variable`, and
`reason`.

``` r

x[, .(species, site, date, caught, released, nest_id, observer)] |>
  is.na_validator(reason = "Mandatory capture field.") |>
  print()
```

       rowid variable                   reason
       <int>   <char>                   <char>
    1:     3  species Mandatory capture field.

Use
[`try_validator()`](https://mpio-be.github.io/DataEntry/reference/try_validator.md)
around each validator when you build an inspector (see below). If a
validator errors, or if it returns the wrong format,
[`try_validator()`](https://mpio-be.github.io/DataEntry/reference/try_validator.md)
converts the problem into a regular validation result instead of
stopping the whole inspection.

``` r

x[, .(species, site, date, caught, released, nest_id, observer)] |>
  is.na_validator(reason = "Mandatory capture field.") |>
  try_validator(nam = "mandatory capture fields") |>
  print()
```

       rowid variable                   reason
       <int>   <char>                   <char>
    1:     3  species Mandatory capture field.

The `nam` value should be short and recognizable. It is used in the
message shown when the validator itself fails.

## Use Curly Brackets For Local Setup

If you use helper objects, define them inside curly brackets. This keeps
the objects local to the validator expression and makes it easier to
move the code into the inspectors table later.

``` r

{
  z <- x[, .(
    species,
    site,
    capture_status,
    age,
    tag_type,
    rowid
  )]

  v <- data.table(
    variable = names(z)[names(z) != "rowid"],
    set = list(
      c("BADO", "WRYB", "SNZD", "BFDO"),
      c("AR", "CH", "CR"),
      c("F", "R", "C", "D"),
      c("A", "J", "C"),
      c("PTT", "GPS", "GEO")
    )
  )

  is.element_validator(
    z,
    v = v,
    reason = "Value is not in the allowed set."
  )
} |>
  try_validator(nam = "allowed values") |>
  print()
```

       rowid variable                           reason
       <int>   <char>                           <char>
    1:     2     site Value is not in the allowed set.

This pattern is useful for validators that need a rule table, a lookup
table, or a temporary subset before calling one of the package
validators.

## Write A Custom Validator

Use a custom validator when a rule needs more than a single-column
check.

This example validates that release time is after capture time.

``` r

release_after_capture_validator <- function(x) {
  z <- copy(x)

  z[, caught_at := as.POSIXct(
    paste(date, caught),
    format = "%Y-%m-%d %H:%M",
    tz = "UTC"
  )]

  z[, released_at := as.POSIXct(
    paste(date, released),
    format = "%Y-%m-%d %H:%M",
    tz = "UTC"
  )]

  z[
    !is.na(caught_at) &
      !is.na(released_at) &
      released_at < caught_at,
    .(
      rowid,
      variable = "released",
      reason = "Release time is before capture time."
    )
  ]
}

x[, .(date, caught, released, rowid)] |>
  release_after_capture_validator() |>
  print()
```

       rowid variable                               reason
       <int>   <char>                               <char>
    1:     2 released Release time is before capture time.

The body could be written with `dplyr`, base R, or any other framework.
The important part is returning `rowid`, `variable`, and `reason`.

## A More Complex Example

The next rule checks whether a first-capture colour combination already
exists in all other years.

In a real inspector, the archive could come from a database query.
Locally, use a small reproducible table with the same columns.

``` r

archive <- data.table(
  UL = c("FWAC", "FWZZ"),
  LL = c("R", "B"),
  UR = c("X", "FWUV"),
  LR = c("W", "Y")
)

{
  z <- x[capture_status == "F", .(UL, LL, UR, LR, rowid)]

  z[, combo := do.call(paste0, .SD), .SDcols = c("UL", "LL", "UR", "LR")]

  archive_combo <- copy(archive)[
    ,
    combo := do.call(paste0, .SD),
    .SDcols = c("UL", "LL", "UR", "LR")
  ][, unique(combo)]

  is.duplicate_validator(
    z[, .(combo, rowid)],
    v = data.table(
      variable = "combo",
      set = list(archive_combo)
    ),
    reason = "Colour combination already exists in the archive. Is this a recapture?"
  )
} |>
  try_validator(nam = "double colour combo") |>
  print()
```

       rowid variable
       <int>   <char>
    1:     1    combo
    2:     4    combo
                                                                       reason
                                                                       <char>
    1: Colour combination already exists in the archive. Is this a recapture?
    2: Colour combination already exists in the archive. Is this a recapture?

This is still just a validator expression. It creates intermediate
objects, builds a derived column, and then returns `rowid`, `variable`,
and `reason`.

## Compose Existing Validators as Inspectors

Inspectors are lists of validators. Add a comma between validator
expressions.

The expression below is the kind of code that can be added to the
`inspectors` table. Once it is stored for a table, DataEntry evaluates
it with that table available as `x`.

``` r

list(
  x[, .(species, site, date, caught, released, nest_id, observer)] |>
    is.na_validator(reason = "Mandatory capture field.") |>
    try_validator(nam = "mandatory capture fields"),
  {
    z <- x[, .(
      species,
      site,
      capture_status,
      age,
      tag_type,
      rowid
    )]

    v <- data.table(
      variable = names(z)[names(z) != "rowid"],
      set = list(
        c("BADO", "WRYB", "SNZD", "BFDO"),
        c("AR", "CH", "CR"),
        c("F", "R", "C", "D"),
        c("A", "J", "C"),
        c("PTT", "GPS", "GEO")
      )
    )

    is.element_validator(
      z,
      v = v,
      reason = "Value is not in the allowed set."
    )
  } |>
    try_validator(nam = "allowed values"),
  x[, .(date, caught, released, rowid)] |>
    release_after_capture_validator() |>
    try_validator(nam = "release after capture"),
  {
    archive <- data.table(
      UL = c("FWAC", "FWZZ"),
      LL = c("R", "B"),
      UR = c("X", "FWUV"),
      LR = c("W", "Y")
    )

    z <- x[capture_status == "F", .(UL, LL, UR, LR, rowid)]

    z[, combo := do.call(paste0, .SD), .SDcols = c("UL", "LL", "UR", "LR")]

    archive_combo <- copy(archive)[
      ,
      combo := do.call(paste0, .SD),
      .SDcols = c("UL", "LL", "UR", "LR")
    ][, unique(combo)]

    is.duplicate_validator(
      z[, .(combo, rowid)],
      v = data.table(
        variable = "combo",
        set = list(archive_combo)
      ),
      reason = "Colour combination already exists in the archive. Is this a recapture?"
    )
  } |>
    try_validator(nam = "double colour combo")
)
```

    [[1]]
       rowid variable                   reason
       <int>   <char>                   <char>
    1:     3  species Mandatory capture field.

    [[2]]
       rowid variable                           reason
       <int>   <char>                           <char>
    1:     2     site Value is not in the allowed set.

    [[3]]
       rowid variable                               reason
       <int>   <char>                               <char>
    1:     2 released Release time is before capture time.

    [[4]]
       rowid variable
       <int>   <char>
    1:     1    combo
    2:     4    combo
                                                                       reason
                                                                       <char>
    1: Colour combination already exists in the archive. Is this a recapture?
    2: Colour combination already exists in the archive. Is this a recapture?

For building your own validators, work locally first. Use a subset of
the table that should fail validation. Once the output has the three
required columns and the row ids point to the rows you expect, move the
expression into the inspector for the table.
