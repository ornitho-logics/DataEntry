# tests/testthat/test-validators.R

library(data.table)

validator_key = function(x) {
  paste(x$rowid, x$variable, sep = ":")
}

test_that("is.na_validator reports missing values by row and variable", {
  x = data.table(
    a = c(1, NA, 3),
    b = c(NA, 2, NA)
  )

  out = is.na_validator(x)

  expect_s3_class(out, "data.table")
  expect_setequal(validator_key(out), c("2:a", "1:b", "3:b"))
  expect_true(all(out$reason == "mandatory"))
})

test_that("POSIXct_validator reports invalid, old, and future datetimes", {
  valid = format(Sys.time() - 3600, "%Y-%m-%d %H:%M")
  old = format(Sys.time() - 3600 * 24 * 10, "%Y-%m-%d %H:%M")
  future = format(Sys.Date() + 2, "%Y-%m-%d")

  x = data.table(
    datetime_ = c(valid, old, future, "bad", NA)
  )

  out = POSIXct_validator(x, ago = 7)

  expect_setequal(
    validator_key(out),
    c("2:datetime_", "3:datetime_", "4:datetime_")
  )
})

test_that("hhmm_validator validates strict HH:MM strings and ignores NA", {
  x = data.table(
    a = c("00:00", "24:00", NA),
    b = c("23:59", "7:00", "12:60")
  )

  out = hhmm_validator(x)

  expect_setequal(validator_key(out), c("2:a", "2:b", "3:b"))
  expect_true(all(out$reason == "invalid time"))
})

test_that("date_validator validates yyyy-mm-dd-like dates", {
  x = data.table(
    d = c("2024-01-01", "2024-13-01", "2024-01-32", "2024/01/01", NA)
  )

  out = date_validator(x)

  expect_setequal(validator_key(out), c("2:d", "3:d", "4:d"))
})

test_that("datetime_validator validates datetime strings without seconds", {
  x = data.table(
    dt = c(
      "2024-01-01 00:00",
      "2024-01-01 24:00",
      "2024-01-01",
      "bad",
      NA
    )
  )

  out = datetime_validator(x)

  expect_setequal(validator_key(out), c("2:dt", "3:dt", "4:dt"))
})

test_that("datetime_validatorSS validates datetime strings with seconds", {
  x = data.table(
    dt = c(
      "2024-01-01 00:00:00",
      "2024-01-01 00:00",
      "2024-01-01 00:00:60",
      NA
    )
  )

  out = datetime_validatorSS(x)

  expect_setequal(validator_key(out), c("2:dt", "3:dt"))
})

test_that("time_order_validator detects reversed and too-long intervals", {
  x = data.table(
    cap_time = c("10:04", "16:40", "01:55"),
    bleeding_time = c("10:10", "16:30", "04:08")
  )

  out = time_order_validator(
    x,
    time1 = "cap_time",
    time2 = "bleeding_time",
    time_max = 60
  )

  expect_equal(out$rowid, c(2L, 3L))
  expect_true(all(out$variable == "cap_time"))
})

test_that("datetime_order_validator detects reversed and too-long intervals", {
  x = data.table(
    start = c(
      "2024-01-01 10:00:00",
      "2024-01-01 10:00:00",
      "2024-01-01 10:00:00"
    ),
    end = c("2024-01-01 10:30:00", "2023-12-31 10:00:00", "2024-02-15 10:00:00")
  )

  out = datetime_order_validator(
    x,
    time1 = "start",
    time2 = "end",
    units = "days",
    time_max = 30
  )

  expect_equal(out$rowid, c(2L, 3L))
  expect_true(all(out$variable == "start"))
})

test_that("interval_validator reports values outside configured bounds", {
  x = data.table(measure = c(1, 10, 0, 11, NA))
  v = data.table(variable = "measure", lq = 1, uq = 10)

  out = interval_validator(x, v)

  expect_setequal(validator_key(out), c("3:measure", "4:measure"))
})

test_that("nchar_validator reports strings with the wrong length", {
  x = data.table(
    id = c("AB", "A", "ABC", NA)
  )
  v = data.table(variable = "id", n = 2L)

  out = nchar_validator(x, v)

  expect_setequal(validator_key(out), c("2:id", "3:id"))
})

test_that("is.element_validator reports values outside allowed sets", {
  x = data.table(
    sex = c("M", "F", "X", NA),
    author = c("AI", "CS", "ZZ", NA)
  )
  v = data.table(
    variable = c("sex", "author"),
    set = list(c("M", "F"), c("AI", "CS", "GS"))
  )

  out = is.element_validator(x, v)

  expect_setequal(validator_key(out), c("3:sex", "3:author"))
})

test_that("is.duplicate_validator reports values present in existing sets", {
  x = data.table(
    id = c("A", "B", "C", NA)
  )
  v = data.table(
    variable = "id",
    set = list(c("A", "C"))
  )

  out = is.duplicate_validator(x, v)

  expect_setequal(validator_key(out), c("1:id", "3:id"))
})

test_that("is.identical_validator reports values not identical to configured value", {
  x = data.table(
    species = c("bird", "bird", "fish", NA)
  )
  v = data.table(
    variable = "species",
    x = "bird"
  )

  out = is.identical_validator(x, v)

  expect_setequal(validator_key(out), c("3:species"))
})

test_that("is.regexp_validator reports pattern mismatches", {
  x = data.table(
    id = c("x2-011-05-19", "x2-011-05-2019", "bad", NA)
  )

  out = is.regexp_validator(
    x,
    regexp = "^x[1-9]-\\d{3}-\\b(?:05|09|11)\\b-19$"
  )

  expect_setequal(validator_key(out), c("2:id", "3:id"))
})
