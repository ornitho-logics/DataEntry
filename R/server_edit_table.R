#' server_edit_table
#'
#' @export
#' @note uitable, comments, backupdir are hardwired and should be defined in global.R
#'
server_edit_table <- function(input, output, session) {
  hasnov = table_has_nov(table_name)

  rv_data = reactiveVal(hot_db_table(table_name))

  Save <- eventReactive(input$saveButton, {
    save_from_hot(
      input = input,
      table = table_name,
      drop_empty = TRUE
    )
  })

  output$table <- renderRHandsontable({
    req(rv_data())

    rhandsontable(rv_data(), rowHeaders = TRUE) |>
      hot_cols(columnSorting = FALSE, manualColumnResize = TRUE) |>
      hot_rows(fixedRowsTop = 1)
  })

  validation_panel = validation_panel(input, output, Save)

  observeEvent(input$saveButton, {
    x = Save()

    validation = validate_before_save(
      input = input,
      x = x,
      validation_panel = validation_panel
    )

    if (!validation$ok) {
      return(invisible(NULL))
    }

    x = validation$x
    cc = validation$issues
    ignore_validators = validation$ignore_validators

    if (hasnov) {
      x = add_nov_flags(x, cc)
    }

    bk_path = save_backup(
      x,
      table_name,
      backup_dir = backupdir
    )

    message("DataEntry backup written to: ", bk_path)

    con = db_con()
    on.exit(DBI::dbDisconnect(con), add = TRUE)

    DBI::dbBegin(con)

    table_saved = tryCatch(
      {
        DBI::dbExecute(
          con,
          paste("DELETE FROM", table_name)
        )

        DBI::dbWriteTable(
          con,
          table_name,
          x,
          append = TRUE,
          row.names = FALSE
        )
      },
      error = function(e) {
        message("DataEntry save failed: ", conditionMessage(e))
        FALSE
      }
    )

    if (!isTRUE(table_saved)) {
      DBI::dbRollback(con)
      return(invisible(FALSE))
    }

    DBI::dbCommit(con)

    rv_data(hot_db_table(table_name))
    validation_panel$open(FALSE)

    updated_table_feedback(bk_path)

    invisible(TRUE)
  })

  server_cheatsheet_modal(input)

  session$allowReconnect(TRUE)
}
