# tests/testthat/test-inspector.R

library(data.table)

test_that("try_validator returns valid validator output unchanged", {
  ev = data.frame(
    rowid = "1",
    variable = "a",
    reason = "bad"
  )

  out = try_validator(ev, nam = "valid")

  expect_equal(out, ev)
})

test_that("try_validator converts validator errors into validator-shaped output", {
  out = try_validator(stop("boom"), nam = "broken")

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_match(out$reason, "broken")
  expect_match(out$reason, "returned an error")
})

test_that("try_validator catches outputs with the wrong shape", {
  out = try_validator(data.frame(a = 1), nam = "wrong")

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_match(out$reason, "does not return the correct format")
})

test_that("evalidators combines validator outputs by variable and reason", {
  L = list(
    data.table(rowid = c(1L, 2L), variable = "a", reason = "bad"),
    data.table(rowid = 3L, variable = "a", reason = "bad"),
    data.table(rowid = 2L, variable = "b", reason = "missing")
  )

  out = evalidators(L)

  expect_s3_class(out, "data.table")
  expect_equal(nrow(out), 2L)
  expect_equal(out[variable == "a" & reason == "bad", rowid], "1,2,3")
  expect_equal(out[variable == "b" & reason == "missing", rowid], "2")
})

test_that("inspector.default returns a validator-shaped message", {
  out = inspector(data.frame(a = 1))

  expect_named(out, c("rowid", "variable", "reason"))
  expect_true(is.na(out$rowid))
  expect_true(is.na(out$variable))
  expect_equal(out$reason, "Validators are not available for this table!")
})

test_that("inspector_loader sources inspector files into the global environment", {
  path = tempfile(fileext = ".R")
  writeLines(
    paste(
      "inspector.my_table = function(x) {",
      "  data.frame(rowid = 1, variable = 'a', reason = 'bad')",
      "}",
      sep = "\n"
    ),
    path
  )

  on.exit(
    {
      if (exists("inspector.my_table", envir = .GlobalEnv)) {
        rm("inspector.my_table", envir = .GlobalEnv)
      }
    },
    add = TRUE
  )

  inspector_loader(path)

  expect_true(exists("inspector.my_table", envir = .GlobalEnv))

  x = data.table(a = 1)
  class(x) = c(class(x), "my_table")

  out = inspector(x)

  expect_equal(out$rowid, 1)
  expect_equal(out$variable, "a")
  expect_equal(out$reason, "bad")
})

test_that("inspector_loader warns but does not error on missing files", {
  expect_warning(
    inspector_loader("missing-inspector-file.R"),
    "Could not source"
  )
})
