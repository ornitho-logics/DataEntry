for (server_name in c("server_append_rows", "server_edit_table")) {
  local({
    name <- server_name
    test_that(paste(name, "shares one fresh validation result per Save"), {
      ns <- asNamespace("DataEntry")
      env <- new.env(parent = ns)
      server <- get(name, ns)
      environment(server) <- env
      state <- new.env(parent = emptyenv())
      state$seen <- integer()
      state$rows <- data.table::data.table(id = 1L)
      env$app_global <- function(name, default = NULL) {
        if (name == "table_name") "synthetic_table" else default
      }
      env$table_has_nov <- function(...) FALSE
      env$column_comment <- function(...) data.table::data.table()
      env$hot_append_table <- env$hot_db_table <- function(...) state$rows
      env$save_from_hot <- function(...) data.table::copy(state$rows)
      env$validation_issues <- function(x, table_name, ...) {
        state$seen <- c(state$seen, x$id)
        data.table::data.table(rowid = 1L, variable = "id",
                              reason = paste("Synthetic issue", x$id))
      }
      for (helper in c("validation_panel", "validate_before_save")) {
        fun <- get(helper, ns)
        environment(fun) <- env
        env[[helper]] <- fun
      }
      env$server_cheatsheet_modal <- env$showNotification <- env$runjs <- function(...) NULL
      env$append_db_table <- env$replace_db_table <- function(...) {
        fail("Invalid entries must not reach the database writer")
      }

      shiny::testServer(server, {
        session$setInputs(saveButton = 1L)
        session$flushReact()
        expect_match(output$invalid_entries_panel$html, "Synthetic issue 1", fixed = TRUE)
        expect_identical(state$seen, 1L)
        session$setInputs(close_invalid_entries = 1L)
        session$flushReact()
        validation_panel$open(TRUE)
        session$flushReact()
        expect_match(output$invalid_entries_panel$html, "Synthetic issue 1", fixed = TRUE)
        expect_identical(state$seen, 1L)
        state$rows$id <- 2L
        session$setInputs(saveButton = 2L)
        session$flushReact()
        expect_match(output$invalid_entries_panel$html, "Synthetic issue 2", fixed = TRUE)
        expect_identical(state$seen, c(1L, 2L))
      })
    })
  })
}
