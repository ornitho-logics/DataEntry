#' @rdname dataentry_servers
#' @export
#'
#' @note See `global.R` in `inst/UI/editInspector` for required variables to set.
server_edit_rcode <- function(input, output, session) {
  table_name <- app_global("table_name", "inspectors")
  code_column <- app_global("code_column", "inspector")
  backupdir <- app_global("backupdir", tempdir())
  id_column <- app_global("id_column", "table_name")

  exclude_columns <- app_global("exclude_columns", character())

  n_empty_lines <- app_global("n_empty_lines", 2) |> as.integer()
  code_column_width <- app_global("code_column_width", 760) |> as.integer()
  code_row_height <- app_global("code_row_height", 100) |> as.integer()
  fixed_rows_top <- app_global("fixed_rows_top", 0) |> as.integer()

  inspector_issues <- function(x) {
    list(
      x[, c(id_column, code_column), with = FALSE] |>
        is.na_validator(),
      x[, code_column, with = FALSE] |>
        rcode_validator(column = code_column)
    ) |>
      evalidators(msg = "Validation failed. This is an internal error.")
  }

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

    rv_data() |>
      rhandsontable(
        rowHeaders = TRUE,
        afterGetColHeader = js_hot_tippy_header(comments, "description")
      ) |>
      hot_cols(
        columnSorting = FALSE,
        manualColumnResize = TRUE,
        autoColumnSize = TRUE,
        stretchH = "none"
      ) |>
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
  })

  validation_panel <- validation_panel(
    input = input,
    output = output,
    Save = Save,
    issues = inspector_issues
  )

  observeEvent(input$saveButton, {
    x <- Save()

    validation <- validate_before_save(
      input = input,
      x = x,
      validation_panel = validation_panel,
      issues = inspector_issues,
      allow_ignore = FALSE
    )

    if (!validation$ok) {
      return(invisible(NULL))
    }

    bk_path <- replace_db_table(
      validation$x,
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
