library(data.table)

local_dataentry_cnf <- function() {
  cnf <- system.file("database/DataTable.cnf", package = "DataEntry")

  skip_if(cnf == "", "DataTable.cnf not installed with package")

  withr::local_envvar(
    DATAENTRY_CNF = cnf
  )

  withr::local_options(
    DataEntry.group = "DataEntry"
  )

  cnf
}
test_that("db_con opens a MariaDB connection from package cnf", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  con <- try(db_con(), silent = TRUE)
  skip_if(inherits(con, "try-error"), "Cannot connect to MariaDB test backend")

  on.exit(DBI::dbDisconnect(con), add = TRUE)

  expect_true(DBI::dbIsValid(con))
  expect_true(inherits(con, "MariaDBConnection"))
})

test_that("db_get returns a data.table from MariaDB", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out <- try(db_get("select 1 as n"), silent = TRUE)
  skip_if(inherits(out, "try-error"), "Cannot query MariaDB test backend")

  expect_s3_class(out, "data.table")
  expect_equal(out$n, 1)
})

test_that("emptyFrame works against the configured MariaDB data_entry table", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out <- try(emptyFrame(table = "data_entry"), silent = TRUE)
  skip_if(inherits(out, "try-error"), "Cannot query data_entry table")

  expect_s3_class(out, "data.table")
  expect_gt(nrow(out), 0)
})

test_that("emptyFrame supports preFilled and colorder against MariaDB", {
  skip_if_not_installed("RMariaDB")

  local_dataentry_cnf()

  out <- try(
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

test_that("save_backup uses active database name when db is not supplied", {
  backup_dir <- withr::local_tempdir()

  local_mocked_bindings(
    db_con = function(...) structure(list(), class = "DBIConnection"),
    .package = "DataEntry"
  )

  local_mocked_bindings(
    dbGetQuery = function(conn, statement, ...) {
      expect_equal(statement, "SELECT DATABASE() AS db")
      data.frame(db = "active_db")
    },
    dbDisconnect = function(conn, ...) TRUE,
    .package = "DBI"
  )

  path <- save_backup(
    x = data.table(a = 1),
    name = "inspectors",
    backup_dir = backup_dir
  )

  expect_true(file.exists(path))

  expect_equal(
    dirname(path),
    as.character(fs::path(backup_dir, "active_db"))
  )

  expect_match(
    basename(path),
    "^backup_active_db_inspectors_[0-9]{8}_[0-9]{6}\\.csv$"
  )
})

test_that("save_backup falls back when active database name cannot be resolved", {
  backup_dir <- withr::local_tempdir()

  local_mocked_bindings(
    db_con = function(...) stop("no connection"),
    .package = "DataEntry"
  )

  path <- save_backup(
    x = data.table(a = 1),
    name = "inspectors",
    backup_dir = backup_dir
  )

  expect_true(file.exists(path))

  expect_equal(
    dirname(path),
    as.character(fs::path(backup_dir, "database"))
  )

  expect_match(
    basename(path),
    "^backup_database_inspectors_[0-9]{8}_[0-9]{6}\\.csv$"
  )
})


test_that("append_db_table writes rows and disconnects", {
  calls <- new.env(parent = emptyenv())
  calls$db_write_table <- NULL
  calls$disconnected <- FALSE

  local_mocked_bindings(
    db_con = function(...) structure(list(), class = "DBIConnection"),
    .package = "DataEntry"
  )

  local_mocked_bindings(
    dbWriteTable = function(conn, name, value, append, row.names, ...) {
      calls$db_write_table <- list(
        conn = conn,
        name = name,
        value = value,
        append = append,
        row.names = row.names
      )

      TRUE
    },
    dbDisconnect = function(conn, ...) {
      calls$disconnected <- TRUE
      TRUE
    },
    .package = "DBI"
  )

  x <- data.table(a = 1:2, b = c("x", "y"))

  out <- append_db_table(x, "data_entry")

  expect_true(out$ok)
  expect_null(out$error)
  expect_null(out$message)

  expect_equal(calls$db_write_table$name, "data_entry")
  expect_equal(calls$db_write_table$value, x)
  expect_true(calls$db_write_table$append)
  expect_false(calls$db_write_table$row.names)

  expect_true(calls$disconnected)
})
