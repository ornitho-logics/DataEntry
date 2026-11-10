local_read_backend <- function(.local_envir = parent.frame()) {
  state <- new.env(parent = emptyenv())
  state$opened <- 0L
  state$closed <- integer()
  state$queries <- list()
  state$valid <- TRUE
  state$fail <- FALSE
  state$session <- list(userData = new.env(parent = emptyenv()))
  state$cleanup <- list()

  testthat::local_mocked_bindings(
    db_connection_settings = function(.cnf = "fake.cnf", group = "fake") {
      list(.cnf = .cnf, group = group)
    },
    db_con = function(...) {
      state$opened <- state$opened + 1L
      list(id = state$opened)
    },
    .package = "DataEntry", .env = .local_envir
  )
  testthat::local_mocked_bindings(
    getDefaultReactiveDomain = function() state$session,
    onStop = function(fun, session) {
      state$cleanup[[length(state$cleanup) + 1L]] <- fun
    },
    .package = "shiny", .env = .local_envir
  )
  testthat::local_mocked_bindings(
    dbIsValid = function(dbObj, ...) state$valid,
    dbDisconnect = function(conn, ...) {
      state$closed <- c(state$closed, conn$id)
      TRUE
    },
    dbGetQuery = function(conn, statement, ..., params = NULL) {
      state$queries[[length(state$queries) + 1L]] <- list(
        id = conn$id, sql = statement, params = params
      )
      if (state$fail) stop("invented query failure")
      data.frame(n = 1L)
    },
    dbReadTable = function(conn, name, ...) data.frame(n = 1L),
    .package = "DBI", .env = .local_envir
  )
  state
}

test_that("reads reuse one connection and forward query parameters", {
  state <- local_read_backend()
  expect_s3_class(db_get("SELECT 1"), "data.table")
  db_get("SELECT ?", params = list(2L))
  expect_equal(state$opened, 1L)
  expect_length(state$closed, 0L)
  expect_equal(state$queries[[2L]]$params, list(2L))
  expect_length(state$cleanup, 1L)
  state$cleanup[[1L]]()
  expect_equal(state$closed, 1L)
  db_get("SELECT 1")
  expect_equal(state$opened, 2L)
  expect_length(state$cleanup, 2L)
})

test_that("changed settings and invalid connections cause replacement", {
  state <- local_read_backend()
  db_get("SELECT 1")
  db_get("SELECT 1", group = "other")
  expect_equal(state$opened, 2L)
  expect_equal(state$closed, 1L)
  state$valid <- FALSE
  db_get("SELECT 1", group = "other")
  expect_equal(state$opened, 3L)
  expect_equal(state$closed, 1:2)
})

test_that("failed queries discard connections without replaying SQL", {
  state <- local_read_backend()
  state$fail <- TRUE
  expect_error(db_get("SELECT 1"), "invented query failure")
  expect_length(state$queries, 1L)
  expect_equal(state$closed, 1L)
  state$fail <- FALSE
  db_get("SELECT 1")
  expect_equal(state$opened, 2L)
})

test_that("sessions isolate connections and standalone reads close immediately", {
  state <- local_read_backend()
  state$session <- NULL
  db_get("SELECT 1")
  expect_equal(state$closed, 1L)
  expect_length(state$cleanup, 0L)
  first <- list(userData = new.env(parent = emptyenv()))
  second <- list(userData = new.env(parent = emptyenv()))
  state$session <- first
  db_get("SELECT 1")
  db_get("SELECT 1")
  state$session <- second
  db_get("SELECT 1")
  expect_equal(state$opened, 3L)
  expect_length(state$cleanup, 2L)
  state$cleanup[[1L]]()
  expect_equal(state$closed, 1:2)
  state$session <- second
  db_get("SELECT 1")
  expect_equal(state$opened, 3L)
})

test_that("table editors share the read connection with metadata queries", {
  state <- local_read_backend()
  db_get("SELECT 1")
  rows <- hot_db_table("invented", n_empty = 2L)
  expect_equal(nrow(rows), 3L)
  expect_equal(state$opened, 1L)
  expect_length(state$closed, 0L)
})
