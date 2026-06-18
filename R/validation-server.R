validation_panel <- function(input, output, Save, table_name) {
  open = reactiveVal(FALSE)

  observeEvent(input$close_invalid_entries, {
    open(FALSE)
  })

  output$invalid_entries_panel = renderUI({
    req(open())

    invalid_entries =
      Save() |>
      validation_issues(table_name = table_name)

    if (nrow(invalid_entries) == 0) {
      return(NULL)
    }

    invalid_table =
      invalid_entries |>
      tableHTML(
        rownames = FALSE
      )

    shinyjqui::jqui_draggable(
      tags$aside(
        class = "dataentry-issues-panel",
        tags$div(
          class = "dataentry-issues-panel-header",
          tags$h4("Invalid entries:"),
          actionButton(
            inputId = "close_invalid_entries",
            label = NULL,
            icon = icon("xmark"),
            class = "dataentry-issues-panel-close"
          )
        ),
        tags$div(
          class = "dataentry-issues-panel-body",
          HTML(as.character(invalid_table))
        )
      ),
      options = list(
        handle = ".dataentry-issues-panel-header",
        containment = "window",
        scroll = FALSE
      )
    )
  })

  list(
    open = open
  )
}

validate_before_save <- function(input, x, table_name, validation_panel) {
  issues = validation_issues(x, table_name = table_name)
  ignore_validators = isTRUE(input$ignore_checks)

  if (nrow(issues) > 0 && !ignore_validators) {
    validation_panel$open(TRUE)

    showNotification(
      ui = "Invalid entries. Nothing was saved.",
      type = "warning",
      duration = 5,
      closeButton = TRUE
    )

    return(
      list(
        ok = FALSE,
        x = x,
        issues = issues,
        ignore_validators = ignore_validators
      )
    )
  }

  list(
    ok = TRUE,
    x = x,
    issues = issues,
    ignore_validators = ignore_validators
  )
}
