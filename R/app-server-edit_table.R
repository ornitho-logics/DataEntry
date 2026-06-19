#' server_edit_table
#'
#' @export
#' @note see global.R in inst/UI/editData for required variables to set.
#'
server_edit_table <- function(input, output, session) {
  table_name = app_global("table_name")
  backupdir = app_global("backupdir", tempdir())

  exclude_columns = app_global("exclude_columns", character())

  n_empty_lines = app_global("n_empty_lines", 5) |> as.integer()

  code_column = app_global("code_column", NULL)
  code_column_width = app_global("code_column_width", 760) |> as.integer()
  code_row_height = app_global("code_row_height", 165) |> as.integer()
  fixed_rows_top = app_global("fixed_rows_top", 0) |> as.integer()

  has_code_column = is.character(code_column)

  hasnov = table_has_nov(table_name)

  comments = column_comment(
    table = table_name,
    exclude_columns = exclude_columns
  )

  rv_data = reactiveVal(
    hot_db_table(
      n_empty = n_empty_lines,
      table = table_name,
      exclude_columns = exclude_columns
    )
  )

  Save <- eventReactive(input$saveButton, {
    save_from_hot(
      input = input,
      table = table_name,
      drop_empty = TRUE
    )
  })

  output$table <- renderRHandsontable({
    req(rv_data())

    x = rv_data()

    out =
      rhandsontable(
        x,
        rowHeaders = TRUE,
        afterGetColHeader = js_hot_tippy_header(comments, "description")
      ) |>
      hot_cols(
        columnSorting = FALSE,
        manualColumnResize = TRUE,
        autoColumnSize = TRUE,
        stretchH = "none"
      )

    if (has_code_column) {
      out =
        out |>
        hot_rows(
          fixedRowsTop = fixed_rows_top,
          rowHeights = code_row_height
        ) |>
        hot_col(
          code_column,
          type = "text",
          width = code_column_width,
          renderer = js_hot_code_cell_renderer(),
          codeCellHeight = code_row_height
        )
    } else {
      out =
        out |>
        hot_rows(fixedRowsTop = fixed_rows_top)
    }

    out
  })

  validation_panel = validation_panel(
    input = input,
    output = output,
    Save = Save,
    table_name = table_name
  )

  observeEvent(input$saveButton, {
    x = Save()

    validation = validate_before_save(
      input = input,
      x = x,
      table_name = table_name,
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

    rv_data(
      hot_db_table(
        n_empty = n_empty_lines,
        table = table_name,
        exclude_columns = exclude_columns
      )
    )

    validation_panel$open(FALSE)

    updated_table_feedback(bk_path)

    invisible(TRUE)
  })

  server_cheatsheet_modal(input)

  session$onFlushed(
    once = TRUE,
    function() {
      if (has_code_column) {
        removeUI(
          selector = "div:has(> #ignore_checks)",
          immediate = TRUE
        )
      }
    }
  )

  session$allowReconnect(TRUE)
}
