#' server_append_rows
#'
#' @export
#' @note uitable, comments are hardwired and should be defined in global.R
#'       inspectors are loaded with [inspector_loader()]
#'
server_append_rows <- function(input, output, session) {
  hasnov = table_has_nov(table_name)

  comments = column_comment(
    table = table_name,
    excludeColumns = exclude_columns
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

    con = db_con()
    on.exit(DBI::dbDisconnect(con), add = TRUE)

    saved_set = tryCatch(
      DBI::dbWriteTable(
        con,
        table_name,
        x,
        append = TRUE,
        row.names = FALSE
      ),
      error = function(e) {
        message("DataEntry append failed: ", conditionMessage(e))
        FALSE
      }
    )

    if (!isTRUE(saved_set)) {
      return(invisible(FALSE))
    }

    validation_panel$open(FALSE)

    disable("saveButton")
    addClass("saveButton", "dataentry-button-disabled")

    msg = if (ignore_validators) {
      "I bet you brushed off that validation for a good reason!"
    } else {
      glue("   <h4> {praise()} </h4>    ")
    }

    showNotification(
      ui = HTML(msg),
      type = "message",
      duration = 20,
      closeButton = TRUE
    )

    msgau = glue(
      "You saved {nrow(x)} rows to the DB.
      <br>"
    )

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
        ),
        tags$p(
          class = "dataentry-save-feedback",
          HTML(msgau)
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
