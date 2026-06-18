# tests/testthat/test-db.R

library(data.table)

local_dataentry_cnf <- function() {
  cnf = system.file("database/DataTable.cnf", package = "DataEntry")
  skip_if(cnf == "", "DataTable.cnf not installed with package")
  assign("cnf_path", cnf, envir = .GlobalEnv)
  cnf
}

test_that("db_con opens a MariaDB connection from package cnf", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  con = try(db_con(), silent = TRUE)
  skip_if(inherits(con, "try-error"), "Cannot connect to MariaDB test backend")

  on.exit(DBI::dbDisconnect(con), add = TRUE)

  expect_true(DBI::dbIsValid(con))
  expect_true(inherits(con, "MariaDBConnection"))
})

test_that("db_get returns a data.table from MariaDB", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out = try(db_get("select 1 as n"), silent = TRUE)
  skip_if(inherits(out, "try-error"), "Cannot query MariaDB test backend")

  expect_s3_class(out, "data.table")
  expect_equal(out$n, 1)
})

test_that("emptyFrame works against the configured MariaDB data_entry table", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out = try(emptyFrame(table = "data_entry"), silent = TRUE)
  skip_if(inherits(out, "try-error"), "Cannot query data_entry table")

  expect_s3_class(out, "data.table")
  expect_gt(nrow(out), 0)
})

test_that("emptyFrame supports preFilled and colorder against MariaDB", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out = try(
    emptyFrame(
      table = "data_entry",
      preFilled = list(datetime_ = as.character(Sys.Date())),
      colorder = c("ID", "sex", "nest")
    ),
    silent = TRUE
  )
  skip_if(inherits(out, "try-error"), "Cannot query data_entry table")

  expect_s3_class(out, "data.table")
  expect_true(all(c("ID", "sex", "nest") %in% names(out)))
  expect_equal(out$datetime_, rep(as.character(Sys.Date()), nrow(out)))
})
