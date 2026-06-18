table_has_nov <- function(table) {
  glue::glue("SHOW COLUMNS FROM {table} LIKE 'nov';") |>
    db_get() |>
    nrow() >
    0
}

drop_empty_hot_rows <- function(x) {
  x[
    !apply(x, 1, function(row) all(is.na(row) | row == "")),
  ]
}

save_from_hot <- function(input, table, drop_empty = FALSE) {
  o = hot_to_r(input$table) |>
    data.table()

  if (drop_empty) {
    o = drop_empty_hot_rows(o)
  }

  o = cleaner(o)

  class(o) = c(class(o), table)

  inspector_loader(path = "inspector.R")

  o
}

validation_issues <- function(x) {
  inspector(x) |>
    evalidators()
}

add_nov_flags <- function(x, issues) {
  x = copy(x)
  x[, nov := 0]

  if (nrow(issues) > 0) {
    x[char2vec(issues$rowid), nov := 1]
  }

  x
}

validation_panel <- function(input, output, Save) {
  open = reactiveVal(FALSE)

  observeEvent(input$close_invalid_entries, {
    open(FALSE)
  })

  output$invalid_entries_panel <- renderUI({
    req(open())

    invalid_entries =
      Save() |>
      validation_issues()

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

validate_before_save <- function(input, x, validation_panel) {
  issues = validation_issues(x)
  ignore_validators = isTRUE(input$ignore_checks)

  if (nrow(issues) > 0 && !ignore_validators) {
    validation_panel$open(TRUE)

    showNotification(
      ui = "Invalid entries. Nothing was saved.",
      type = "warning",
      duration = 5,
      closeButton = TRUE
    )

    return(list(
      ok = FALSE,
      x = x,
      issues = issues,
      ignore_validators = ignore_validators
    ))
  }

  list(
    ok = TRUE,
    x = x,
    issues = issues,
    ignore_validators = ignore_validators
  )
}

server_cheatsheet_modal <- function(input) {
  observeEvent(input$cheatsheetButton, {
    showModal(modalDialog(
      title = "Data entry shortcuts:",
      includeMarkdown(system.file("cheatsheet.md", package = "DataEntry")),
      easyClose = TRUE,
      footer = NULL,
      size = "l"
    ))
  })
}

hot_db_table <- function(table, n_empty = 10) {
  con = db_con()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  dat =
    DBI::dbReadTable(con, table) |>
    setDT() |>
    hot_safe_table()

  empty_rows = as.data.frame(matrix(NA, ncol = ncol(dat), nrow = n_empty))
  names(empty_rows) = names(dat)

  rbind(dat, empty_rows)
}

hot_append_table <- function(
  table,
  n_empty,
  exclude_columns,
  comments,
  pre_filled = list(datetime_ = format(Sys.Date(), "%Y-%m-%d")),
  colorder,
  dropdowns = list()
) {
  x = if (missing(colorder)) {
    emptyFrame(
      table = table,
      n = n_empty,
      excludeColumns = exclude_columns,
      preFilled = pre_filled
    )
  } else {
    emptyFrame(
      table = table,
      n = n_empty,
      excludeColumns = exclude_columns,
      preFilled = pre_filled,
      colorder = colorder
    )
  }

  out =
    x |>
    rhandsontable(
      afterGetColHeader = js_hot_tippy_header(comments, "description")
    ) |>
    hot_cols(columnSorting = FALSE, manualColumnResize = TRUE) |>
    hot_rows(fixedRowsTop = 1)

  for (nm in names(dropdowns)) {
    if (nm %in% names(x)) {
      out =
        out |>
        hot_col(
          col = nm,
          type = "dropdown",
          source = dropdowns[[nm]]
        )
    }
  }

  out
}


# notifications
dataentry_notif <- function(msg, type = "message", duration = 20) {
  showNotification(
    ui = HTML(msg),
    type = type,
    duration = duration,
    closeButton = TRUE
  )
}


updated_table_feedback <- function(bk_path, ...) {
  msg = glue(
    'Table saved!<br>
    Backup stored as <br>
    <code>{bk_path |> basename()}</code>.'
  )

  dataentry_notif(msg = msg, ...)
}


appended_rows_feedback <- function(x, ignore = TRUE, ...) {
  msg = if (ignore) {
    glue(
      "
    <h4>
    You probably had your reasons for skipping validation!
    Anyway, {nrow(x)} rows made it to the DB.
    <span class='dataentry-notification-emoji'>&#128530;</span>
    </h4>
    "
    )
  } else {
    glue(
      "
    <h4>
    {praise()}
    You saved {nrow(x)} rows to the DB.
    <span class='dataentry-notification-emoji'>&#x2726;&#x2726;&#x2726;&#x2726;&#x2726;</span>
    </h4>
    
    "
    )
  }

  dataentry_notif(msg = msg, ...)
}
