# Combine validator outputs

`evalidators()` combines the output of several validators into the
format used by DataEntry inspectors. Rows with the same `variable` and
`reason` are grouped together, and their `rowid` values are collapsed
into a comma-separated string.

## Usage

``` r
evalidators(
  L,
  msg =
    "Inspector validation failed. Open the inspectors table and check the inspector definition."
)
```

## Arguments

- L:

  A list of validator outputs. Each element should contain at least
  `rowid`, `variable`, and `reason`.

- msg:

  Fallback validation message used when validator outputs cannot be
  combined or do not contain `rowid`, `variable`, and `reason`.

## Value

A `data.table` with columns `variable`, `reason`, and `rowid` when
validation succeeds. If validation fails, a `data.frame` with `rowid`,
`variable`, and `reason`.

## Details

If the validator outputs cannot be combined, `evalidators()` returns a
validator-shaped error explaining that the inspector failed.

## Examples

``` r
L = list(
  data.table::data.table(rowid = c(1, 2), variable = "a", reason = "missing"),
  data.table::data.table(rowid = 3, variable = "a", reason = "missing"),
  data.table::data.table(rowid = 2, variable = "b", reason = "invalid")
)

evalidators(L)
#>    variable  reason  rowid
#>      <char>  <char> <char>
#> 1:        a missing  1,2,3
#> 2:        b invalid      2
```
