library(data.table)

test_that("try_validator returns valid validator output unchanged", {
  ev <- data.frame(
    rowid = "1",
    variable = "a",
    reason = "bad"
  )

  out <- try_validator(ev, nam = "valid")

  expect_equal(out, ev)
})

test_that("try_validator converts validator errors into validator-shaped output", {
  out <- try_validator(stop("boom"), nam = "broken")

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_match(out$reason, "broken")
  expect_match(out$reason, "returned an error")
})

test_that("try_validator catches outputs with the wrong shape", {
  out <- try_validator(data.frame(a = 1), nam = "wrong")

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_match(out$reason, "does not return the correct format")
})

test_that("evalidators combines validator outputs by variable and reason", {
  L <- list(
    data.table(rowid = c(1L, 2L), variable = "a", reason = "bad"),
    data.table(rowid = 3L, variable = "a", reason = "bad"),
    data.table(rowid = 2L, variable = "b", reason = "missing")
  )

  out <- evalidators(L)

  expect_s3_class(out, "data.table")
  expect_equal(nrow(out), 2L)
  expect_equal(out[variable == "a" & reason == "bad", rowid], "1,2,3")
  expect_equal(out[variable == "b" & reason == "missing", rowid], "2")
})

test_that("inspector_from_text builds an inspector function from list expression text", {
  inspector <- DataEntry:::inspector_from_text(
    paste(
      "list(",
      "  data.frame(rowid = '1', variable = 'a', reason = 'bad')",
      ")",
      sep = "\n"
    )
  )

  expect_type(inspector, "closure")

  out <-
    inspector(data.table(a = 1)) |>
    evalidators()

  expect_s3_class(out, "data.table")
  expect_equal(nrow(out), 1L)
  expect_equal(out$rowid, "1")
  expect_equal(out$variable, "a")
  expect_equal(out$reason, "bad")
})

test_that("inspector_from_text evaluates inspector text with x in scope", {
  inspector <- DataEntry:::inspector_from_text(
    paste(
      "list(",
      "	x[, .(a)] |> is.na_validator()",
      ")",
      sep = "\n"
    )
  )

  x <- data.table(a = c(1, NA, 3))

  out <-
    inspector(x) |>
    evalidators()

  expect_equal(out$rowid, "2")
  expect_equal(out$variable, "a")
  expect_equal(out$reason, "mandatory")
})

test_that("inspector_loader reads inspector text from db_get", {
  local_mocked_bindings(
    inspectors_table_exists = function() TRUE,
    db_get = function(query, ..., params = NULL) {
      expect_match(query, "SELECT inspector FROM inspectors")
      expect_equal(params, list("data_entry"))

      data.table(
        inspector = paste(
          "list(",
          "  data.frame(rowid = '1', variable = 'a', reason = 'bad')",
          ")",
          sep = "\n"
        )
      )
    },
    .package = "DataEntry"
  )

  inspector <- inspector_loader(table_name = "data_entry")

  expect_type(inspector, "closure")

  out <-
    inspector(data.table(a = 1)) |>
    evalidators()

  expect_equal(out$rowid, "1")
  expect_equal(out$variable, "a")
  expect_equal(out$reason, "bad")
})

test_that("validation_issues loads db inspector and evaluates validators", {
  local_mocked_bindings(
    inspectors_table_exists = function() TRUE,
    db_get = function(query, ..., params = NULL) {
      data.table(
        inspector = paste(
          "list(",
          "	x[, .(a)] |> is.na_validator()",
          ")",
          sep = "\n"
        )
      )
    },
    .package = "DataEntry"
  )

  x <- data.table(a = c(1, NA, 3))

  out <- validation_issues(x, table_name = "data_entry")

  expect_s3_class(out, "data.table")
  expect_equal(nrow(out), 1L)
  expect_equal(out$rowid, "2")
  expect_equal(out$variable, "a")
  expect_equal(out$reason, "mandatory")
})


test_that("inspector_loader returns an empty inspector when inspectors table is missing", {
  local_mocked_bindings(
    inspectors_table_exists = function() FALSE,
    db_get = function(...) {
      fail("db_get should not be called when inspectors table is missing")
    },
    .package = "DataEntry"
  )

  inspector <- inspector_loader(table_name = "data_entry")

  expect_type(inspector, "closure")
  expect_equal(inspector(data.table(a = 1)), list())
})


test_that("evalidators uses custom fallback message", {
  out <- evalidators(
    list(data.table(a = 1)),
    msg = "custom validation failure"
  )

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_equal(out$reason, "custom validation failure")
})
