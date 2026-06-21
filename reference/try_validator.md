# Evaluate a validator safely

`try_validator()` evaluates a validator call and always returns a
validator-shaped object. If the validator errors, or if it returns an
object that does not contain `rowid`, `variable`, and `reason`, the
error is converted to a single validation issue.

## Usage

``` r
try_validator(..., nam = "")
```

## Arguments

- ...:

  A validator expression to evaluate.

- nam:

  A short name used in the error message if the validator fails.

## Value

A `data.frame`, `data.table`, or similar object with at least `rowid`,
`variable`, and `reason`.

## Details

This is useful inside inspectors, where one broken validator should be
reported to the user instead of stopping the whole validation step.

## Examples

``` r
x = data.table::data.table(a = c(1, NA))

try_validator(
  is.na_validator(x),
  nam = "mandatory"
)
#>    rowid variable    reason
#>    <int>   <char>    <char>
#> 1:     2        a mandatory

try_validator(
  stop("broken validator"),
  nam = "broken"
)
#>   rowid variable
#> 1  <NA>     <NA>
#>                                                                 reason
#> 1 Validator “broken” returned an error: Error in try(..., silent = ...
```
