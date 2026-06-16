# tests/testthat/test-utils.R

library(data.table)

test_that("hot_safe_table converts date/time classes to character-safe columns", {
  x = data.table(
    ts = as.POSIXct(c("2024-01-02 03:04:05", NA), tz = "UTC"),
    d = as.Date(c("2024-01-03", NA)),
    dt = as.difftime(c(30, NA), units = "mins"),
    value = c("a", "b")
  )

  out = hot_safe_table(copy(x))

  expect_type(out$ts, "character")
  expect_equal(out$ts[1], "2024-01-02 03:04:05")
  expect_true(is.na(out$ts[2]))

  expect_type(out$d, "character")
  expect_equal(out$d[1], "2024-01-03")
  expect_true(is.na(out$d[2]))

  expect_type(out$dt, "character")
  expect_equal(out$value, c("a", "b"))
})

test_that("cleaner replaces string NA and empty strings in place", {
  x = data.table(
    a = c("NA", "", "x"),
    b = c("", "NA", "y")
  )

  expect_invisible(cleaner(x))

  expect_true(is.na(x$a[1]))
  expect_true(is.na(x$a[2]))
  expect_equal(x$a[3], "x")
  expect_true(is.na(x$b[1]))
  expect_true(is.na(x$b[2]))
  expect_equal(x$b[3], "y")
})

test_that("meltall returns long data with row ids", {
  x = data.table(
    a = c(1, NA),
    b = c("x", "y")
  )

  out = meltall(x, na.rm = FALSE)

  expect_s3_class(out, "data.table")
  expect_named(out, c("rowid", "variable", "value"))
  expect_equal(nrow(out), 4L)
  expect_equal(sort(unique(out$rowid)), 1:2)
  expect_setequal(as.character(out$variable), c("a", "b"))
})

test_that("char2vec parses comma-separated row ids", {
  expect_equal(char2vec(c("1, 2", "2,3", " 4 ")), 1:4)
})

test_that("strp_date_or_time parses date and datetime strings", {
  out = strp_date_or_time(c(
    "2024-01-03 08:15",
    "2024-01-03",
    "not-a-date"
  ))

  expect_s3_class(out, "POSIXct")
  expect_equal(format(out[1], "%Y-%m-%d %H:%M"), "2024-01-03 08:15")
  expect_equal(format(out[2], "%Y-%m-%d %H:%M"), "2024-01-03 00:00")
  expect_true(is.na(out[3]))
})

test_that("save_backup writes a timestamped CSV under the db subdirectory", {
  backup_dir = withr::local_tempdir()

  path = save_backup(
    x = data.table(a = 1:2, b = c("x", "y")),
    name = "data_entry",
    backup_dir = backup_dir,
    db = "testdb"
  )

  expect_true(file.exists(path))

  expect_equal(
    dirname(path),
    as.character(fs::path(backup_dir, "testdb"))
  )

  expect_match(
    basename(path),
    "^backup_testdb_data_entry_[0-9]{8}_[0-9]{6}\\.csv$"
  )

  out = fread(path)

  expect_equal(out$a, 1:2)
  expect_equal(out$b, c("x", "y"))
})
