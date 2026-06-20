# 

     data validators 

all validators (except is.na_validator) ignore NA entries.

## Usage

``` r
is.na_validator(x, reason = "mandatory")

POSIXct_validator(
  x,
  ago = 7,
  reason = "date-time wrong, in the future or older than a week"
)

hhmm_validator(x, reason = "invalid time")

date_validator(x, reason = "invalid date - should be: yyyy-mm-dd")

datetime_validator(
  x,
  reason = "invalid datetime_ - should be: yyyy-mm-dd hh:mm"
)

datetime_validatorSS(
  x,
  reason = "invalid datetime_ - should be: yyyy-mm-dd hh:mm:ss"
)

time_order_validator(
  x,
  time1,
  time2,
  units = "mins",
  reason = "invalid time order or time difference larger than expected",
  time_max = 60
)

datetime_order_validator(
  x,
  time1,
  time2,
  units = "days",
  reason = "invalid datetime order or datetime difference larger than expected",
  time_max = 30
)

interval_validator(x, v, reason = "unusually small or large measure")

nchar_validator(x, v, reason = "incorrect number of characters")

is.element_validator(x, v, reason = "invalid entry")

is.duplicate_validator(x, v, reason = "duplicate entry")

is.identical_validator(x, v, reason = "invalid entry")

is.regexp_validator(x, regexp, reason = "invalid pattern")

rcode_validator(x, column, reason = "invalid R code")
```

## Arguments

- x:

  A data.frame or data.table containing R code.

- reason:

  Validation reason prefix.

- ago:

  number of days indicating old data entry (set to a week)

- time1:

  start datetime to compare

- time2:

  end datetime to compare

- units:

  character string of units

- time_max:

  maximal time difference that is passing validation

- v:

  a data.table containing the validation rules. See notes.

- regexp:

  for is.regexp_validator: a regexp expression

- column:

  Code column to validate.

## Value

       a data.table with two columns: variable (the names of the columns in x)
               and rowid (the position of offending (i.e. not validated) entries).

A data.table with `rowid`, `variable`, and `reason`.

## Note

    `v` for interval_validator: a data.table with variable, lq, uq columns

    `v`  for nchar_validator: a data.table with variable and n (number of characters)

     `v`   for is.element_validator: a data.table with variable and set
               (a vector of lists containing the valid elements for each variable )

     `v`  for is.duplicate_validator: a data.table with variable and set
              (a vector of lists containing the already existing values for each variable )

     `v`   for is.identical_validator: a data.table with variable and x
                 (the value to test against)

## Examples

``` r
x = data.table(v1 = c(1,2, NA, NA), v2  = c(1,2, NA, NA) )
#> Error in data.table(v1 = c(1, 2, NA, NA), v2 = c(1, 2, NA, NA)): could not find function "data.table"
is.na_validator(x)
#> Error: object 'x' not found
t = Sys.time(); d = Sys.Date()
require(data.table)
#> Loading required package: data.table
#> 
#> Attaching package: ‘data.table’
#> The following object is masked from ‘package:base’:
#> 
#>     %notin%
x = data.table(
 v1 = c(NA, as.character(d-1), as.character(t - 3600*24*10 )  ) ,
 v2 = c('2016-11-23 25:23', as.character(t -100) ,as.character(t+100)))
POSIXct_validator(x)
#>    rowid variable                                              reason
#>    <int>   <char>                                              <char>
#> 1:     3       v1 date-time wrong, in the future or older than a week
#> 2:     1       v2 date-time wrong, in the future or older than a week

x = data.table(zz =  c( as.character(d -1), as.character(d ) )  )
POSIXct_validator(x)
#> Empty data.table (0 rows and 3 cols): rowid,variable,reason


x = data.table(v1 = c('02:04' , '16:56', '23:59'  ),
 v2 = c('24:04' , NA, '23:59'  ) )
hhmm_validator(x)
#>    rowid variable       reason
#>    <int>   <char>       <char>
#> 1:     1       v2 invalid time
x = data.table(v1 = c('2017-01-21' , '2012-04-21', '2017-05-21'  ),
               v2 = c('2017' , '2017-01-xx', '2015-01-09'  ) )
print(date_validator(x))
#>    rowid variable                               reason
#>    <int>   <char>                               <char>
#> 1:     1       v2 invalid date - should be: yyyy-mm-dd
#> 2:     2       v2 invalid date - should be: yyyy-mm-dd
x = data.table(v1 = c('2017-01-21 02:04' , '2012-04-21 16:56', '2017-05-21 23:59'  ),
               v2 = c('2017-07-27 00:00' , '2017-01-21', '2015-01-09 23:59'  ) )
datetime_validator(x)
#>    rowid variable                                          reason
#>    <int>   <char>                                          <char>
#> 1:     2       v2 invalid datetime_ - should be: yyyy-mm-dd hh:mm
x = data.table(v1 = c('2017-01-21 02:04:55' , '2012-04-21 16:56:01', '2017-05-21 23:59:00'  ),
               v2 = c('2017-07-27 00:00' , '2017-01-21', '2015-01-09 23:59:01'  ) )
datetime_validatorSS(x)
#>    rowid variable                                             reason
#>    <int>   <char>                                             <char>
#> 1:     1       v2 invalid datetime_ - should be: yyyy-mm-dd hh:mm:ss
#> 2:     2       v2 invalid datetime_ - should be: yyyy-mm-dd hh:mm:ss
x = data.table(cap_time = c('10:04' , '16:40', '01:55'),
               bleeding_time = c('10:10' , '16:30', '04:08'), rowid =1:3)
t = time_order_validator(x, time1 = 'cap_time',
time2 = 'bleeding_time')
x = data.table(cap_time = c('2019-06-03 16:04:47' , '2019-04-05 16:40', '2019-04-05 01:55'),
               bleeding_time = c('2019-06-03 16:00:54' , '2019-04-05 16:30', '2019-04-05 04:08'), rowid = 1:3)
t = time_order_validator(x, time1 = 'cap_time', time2 = 'bleeding_time')
x = data.table(v1 = runif(5)  , v2 = runif(5) )
v = data.table(variable = c('v1', 'v2'), lq = c(-1, 0.2), uq = c(.7, 0.5) )
interval_validator(x,v)
#>    rowid variable                           reason
#>    <int>   <char>                           <char>
#> 1:     2       v1 unusually small or large measure
#> 2:     4       v2 unusually small or large measure
#> 3:     5       v2 unusually small or large measure

 x = data.table(box = c(0, 1, 100, 300))
 v = data.table(variable = 'box', lq = 1, uq = 277 )
interval_validator(x,v)
#>    rowid variable                           reason
#>    <int>   <char>                           <char>
#> 1:     1      box unusually small or large measure
#> 2:     4      box unusually small or large measure
x = data.table(v1 = c('x', 'xy', 'x')  , v2 = c('xx', 'x', 'xxx')  )
v = data.table(variable = c('v1', 'v2'), n = c(1, 2) )
nchar_validator(x, v)
#>    rowid variable                         reason
#>    <int>   <char>                         <char>
#> 1:     2       v1 incorrect number of characters
#> 2:     2       v2 incorrect number of characters
#> 3:     3       v2 incorrect number of characters
x = data.table(v1 = c('A', 'B', 'C')  , v2 = c('ZZ', 'YY', 'QQ')  )
v = data.table(variable = c('v1', 'v2'),
               set = c( list( c('A', 'C') ), list( c('YY')  )) )
is.element_validator(x, v)
#>    rowid variable        reason
#>    <int>   <char>        <char>
#> 1:     2       v1 invalid entry
#> 2:     1       v2 invalid entry
#> 3:     3       v2 invalid entry
x = data.table(v1 = c('A', 'B', 'C')  , v2 = c('ZZ', 'YY', 'QQ')  )
v = data.table(variable = c('v1', 'v2'),
               set = c( list( c('A', 'C') ), list( c('YY')  )) )
is.duplicate_validator(x, v)
#>    rowid variable          reason
#>    <int>   <char>          <char>
#> 1:     1       v1 duplicate entry
#> 2:     3       v1 duplicate entry
#> 3:     2       v2 duplicate entry
x = data.table(v1 = 1:3  , v2 = c('a', 'b', 'c')  )
v = data.table(variable = c('v1', 'v2'),  x = c(1, 'd'))
is.identical_validator(x, v)
#>    rowid variable        reason
#>    <int>   <char>        <char>
#> 1:     2       v1 invalid entry
#> 2:     3       v1 invalid entry
#> 3:     1       v2 invalid entry
#> 4:     2       v2 invalid entry
#> 5:     3       v2 invalid entry
x = data.table(id = c("x2-011-05-19", "x2-011-05-2019", "x2-011-5-2019", "x2-011-  5-2019") )
 is.regexp_validator(x, regexp = "^x[1-9]-\\d{3}-\\b(?:05|09|11)\\b-19$")
#>    rowid variable          reason
#>    <int>   <char>          <char>
#> 1:     2       id invalid pattern
#> 2:     3       id invalid pattern
#> 3:     4       id invalid pattern
```
