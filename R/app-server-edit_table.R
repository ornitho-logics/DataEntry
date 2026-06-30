#' @rdname dataentry_servers
#' @export
#'
#' @note See `global.R` in `inst/UI/editData` for required variables to set.
server_edit_table <- function(input, output, session) {
  table_name <- app_global("table_name")
  backupdir <- app_global("backupdir", tempdir())

  exclude_columns <- app_global("exclude_columns", character())

  n_empty_lines <- app_global("n_empty_lines", 5) |> as.integer()
  fixed_rows_top <- app_global("fixed_rows_top", 0) |> as.integer()

  hasnov <- table_has_nov(table_name)

  comments <- column_comment(
    table = table_name,
    exclude_columns = exclude_columns
  )

  rv_data <- reactiveVal(
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

    x <- rv_data()

    out <-
      rhandsontable(
        x,
        rowHeaders = TRUE,
        afterGetColHeader = js_hot_tippy_header(comments, "description")
      ) |>
      hot_cols(
        columnSorting = FALSE,
        manualColumnResize = TRUE,
        stretchH = "none"
      ) |>
      hot_rows(fixedRowsTop = fixed_rows_top)

    out
  })

  validation_panel <- validation_panel(
    input = input,
    output = output,
    Save = Save,
    table_name = table_name
  )

  observeEvent(input$saveButton, {
    x <- Save()

    validation <- validate_before_save(
      input = input,
      x = x,
      table_name = table_name,
      validation_panel = validation_panel
    )

    if (!validation$ok) {
      return(invisible(NULL))
    }

    x <- validation$x
    cc <- validation$issues

    if (hasnov) {
      x <- add_nov_flags(x, cc)
    }

    bk_path <- replace_db_table(
      x,
      table_name,
      backupdir
    )

    if (!is.character(bk_path)) {
      return(invisible(FALSE))
    }

    runjs("window.DataEntryDirty = false;")

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

  session$allowReconnect(TRUE)
}
