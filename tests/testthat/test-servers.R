library(data.table)

empty_issues <- function(x, table_name, ...) {
  data.table(
    rowid = integer(),
    variable = character(),
    reason = character()
  )
}

mock_globals <- function(values) {
  force(values)

  function(name, default = NULL) {
    if (name %in% names(values)) {
      values[[name]]
    } else {
      default
    }
  }
}

test_that("server_edit_rcode saves valid inspector code", {
  saved <- new.env(parent = emptyenv())
  saved$n <- 0L
  saved$x <- NULL
  saved$table <- NULL

  globals <- list(
    table_name = "inspectors",
    backupdir = tempdir(),
    exclude_columns = character(),
    n_empty_lines = 2,
    code_column = "inspector",
    code_column_width = 760,
    code_row_height = 100,
    fixed_rows_top = 0
  )

  valid_inspector <- data.table(
    table_name = "data_entry",
    inspector = "list(data.frame(rowid = 1, variable = 'a', reason = 'bad'))"
  )

  testthat::local_mocked_bindings(
    app_global = mock_globals(globals),
    column_comment = function(...) data.table(),
    hot_db_table = function(...) valid_inspector,
    save_from_hot = function(...) valid_inspector,
    replace_db_table = function(x, table_name, backupdir) {
      saved$n <- saved$n + 1L
      saved$x <- copy(x)
      saved$table <- table_name
      file.path(backupdir, paste0(table_name, ".csv"))
    },
    updated_table_feedback = function(...) NULL,
    server_cheatsheet_modal = function(...) NULL,
    runjs = function(...) NULL,
    .package = "DataEntry"
  )

  shiny::testServer(DataEntry::server_edit_rcode, {
    session$setInputs(saveButton = 1)
    session$flushReact()

    expect_equal(saved$n, 1L)
    expect_equal(saved$table, "inspectors")
    expect_equal(saved$x, valid_inspector)
  })
})

test_that("server_edit_table saves valid rows", {
  saved <- new.env(parent = emptyenv())
  saved$n <- 0L
  saved$x <- NULL
  saved$table <- NULL

  globals <- list(
    table_name = "data_entry",
    backupdir = tempdir(),
    exclude_columns = character(),
    n_empty_lines = 5,
    fixed_rows_top = 0
  )

  rows <- data.table(id = 1L, value = "ok")

  testthat::local_mocked_bindings(
    app_global = mock_globals(globals),
    table_has_nov = function(...) FALSE,
    column_comment = function(...) data.table(),
    hot_db_table = function(...) rows,
    save_from_hot = function(...) rows,
    validation_issues = empty_issues,
    replace_db_table = function(x, table_name, backupdir) {
      saved$n <- saved$n + 1L
      saved$x <- copy(x)
      saved$table <- table_name
      file.path(backupdir, paste0(table_name, ".csv"))
    },
    updated_table_feedback = function(...) NULL,
    server_cheatsheet_modal = function(...) NULL,
    runjs = function(...) NULL,
    .package = "DataEntry"
  )

  shiny::testServer(DataEntry::server_edit_table, {
    session$setInputs(saveButton = 1)
    session$flushReact()

    expect_equal(saved$n, 1L)
    expect_equal(saved$table, "data_entry")
    expect_equal(saved$x, rows)
  })
})

test_that("server_append_rows appends valid rows", {
  written <- new.env(parent = emptyenv())
  written$n <- 0L
  written$x <- NULL
  written$table <- NULL

  globals <- list(
    table_name = "data_entry",
    exclude_columns = character(),
    n_empty_lines = 20,
    prefilled = list(),
    dropdowns = list()
  )

  rows <- data.table(id = 1L, value = "ok")

  testthat::local_mocked_bindings(
    dbWriteTable = function(conn, name, value, append, row.names, ...) {
      written$n <- written$n + 1L
      written$x <- copy(value)
      written$table <- name

      expect_true(append)
      expect_false(row.names)

      TRUE
    },
    dbDisconnect = function(conn, ...) TRUE,
    .package = "DBI"
  )

  testthat::local_mocked_bindings(
    app_global = mock_globals(globals),
    table_has_nov = function(...) FALSE,
    column_comment = function(...) data.table(),
    hot_append_table = function(...) rows,
    save_from_hot = function(...) rows,
    validation_issues = empty_issues,
    db_con = function(...) structure(list(), class = "mock_db_connection"),
    appended_rows_feedback = function(...) NULL,
    server_cheatsheet_modal = function(...) NULL,
    runjs = function(...) NULL,
    disable = function(...) NULL,
    addClass = function(...) NULL,
    insertUI = function(...) NULL,
    removeUI = function(...) NULL,
    actionBttn = function(...) NULL,
    br = function(...) NULL,
    icon = function(...) NULL,
    .package = "DataEntry"
  )

  shiny::testServer(DataEntry::server_append_rows, {
    session$setInputs(saveButton = 1)
    session$flushReact()

    expect_equal(written$n, 1L)
    expect_equal(written$table, "data_entry")
    expect_equal(written$x, rows)
  })
})
