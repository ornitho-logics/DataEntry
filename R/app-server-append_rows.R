#' server_append_rows
#'
#' @export
#' @note see global.R in inst/UI/newData for required variables to set.
#'
server_append_rows <- function(input, output, session) {
  table_name = app_global("table_name")

  exclude_columns = app_global("exclude_columns", character())
  n_empty_lines = app_global("n_empty_lines", 20) |> as.integer()
  prefilled = app_global("prefilled", list())
  dropdowns = app_global("dropdowns", list())

  hasnov = table_has_nov(table_name)

  comments = column_comment(
    table = table_name,
    exclude_columns = exclude_columns
  )

  append_table =
    hot_append_table(
      table = table_name,
      n_empty = n_empty_lines,
      exclude_columns = exclude_columns,
      pre_filled = prefilled,
      dropdowns = dropdowns,
      comments = comments
    )

  observeEvent(input$refresh, {
    runjs("window.location.reload();")
  })

  Save <- eventReactive(input$saveButton, {
    save_from_hot(
      input = input,
      table = table_name,
      drop_empty = TRUE
    )
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

    con = db_con()
    on.exit(DBI::dbDisconnect(con), add = TRUE)

    DBI::dbWriteTable(
      con,
      table_name,
      x,
      append = TRUE,
      row.names = FALSE
    )

    validation_panel$open(FALSE)

    disable("saveButton")
    addClass("saveButton", "dataentry-button-disabled")

    appended_rows_feedback(x, ignore_validators)

    insertUI(
      selector = "#saveButton",
      where = "afterEnd",
      ui = list(
        br(),
        actionBttn(
          inputId = "refresh",
          label = "Start new",
          style = "material-flat",
          color = "success",
          block = TRUE,
          icon = icon("clone")
        )
      )
    )

    removeUI("#ignore_checks")
    removeUI("#cheatsheetButton")

    invisible(TRUE)
  })

  output$table <- renderRHandsontable({
    append_table
  })

  server_cheatsheet_modal(input)

  session$allowReconnect(TRUE)
}
