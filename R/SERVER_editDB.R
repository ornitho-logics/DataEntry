#' Shiny server function
#'
#' @param input     Shiny server
#' @param output    Shiny server
#' @param session   Shiny server
#'
#' @export
#' @note user,host,db,pwd, uitable, comments, describeTable, getDataSummary,backupdir are hardwired and should be defined in global.R

server_editDB_inPlace <- function(input, output, session) {
  getDBtable <- function() {
    con = dbConnect(
      RMariaDB::MariaDB(),
      host = host,
      user = user,
      db = db,
      password = pwd
    )
    dat = dbReadTable(con, tableName) |>
      setDT() |>
      hot_safe_table()

    dbDisconnect(con)

    empty_rows = as.data.frame(matrix(NA, ncol = ncol(dat), nrow = 10))
    names(empty_rows) = names(dat)
    dat = rbind(dat, empty_rows)

    dat
  }

  rv_data = reactiveVal(getDBtable())

  output$table <- renderRHandsontable({
    req(rv_data())

    rhandsontable(rv_data(), rowHeaders = TRUE) |>
      hot_cols(columnSorting = FALSE, manualColumnResize = TRUE) |>
      hot_rows(fixedRowsTop = 1)
  })

  observeEvent(input$saveButton, {
    editedData = hot_to_r(input$table)
    editedData = editedData[
      !apply(editedData, 1, function(x) all(is.na(x) | x == "")),
    ]

    bk_path = save_backup(editedData, tableName, backup_dir = backupdir)

    con <- dbConnect(
      RMariaDB::MariaDB(),
      host = host,
      user = user,
      db = db,
      password = pwd
    )

    dbBegin(con)

    dbExecute(con, paste("DELETE FROM", tableName))
    tableSaved = dbWriteTable(
      con,
      tableName,
      editedData,
      append = TRUE,
      row.names = FALSE
    )

    if (tableSaved) {
      dbCommit(con)
    } else {
      dbRollback(con)
    }

    dbDisconnect(con)

    rv_data(editedData)

    if (tableSaved) {
      rv_data(getDBtable())

      toastr_success(
        title = "",
        message = paste(
          "Table saved successfully. Backup stored as",
          shQuote(bk_path)
        ),
        timeOut = 5000,
        position = "top-center"
      )
    }
  })

  observeEvent(input$helpButton, {
    showModal(modalDialog(
      tableHTML(
        comments,
        rownames = FALSE,
        collapse = "separate_shiny",
        escape = FALSE
      ) |>
        add_css_table(css = list("font-size", "1.2vw")) |>
        add_theme('rshiny-blue'),
      title = "Columns definition:",
      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  observeEvent(input$tableInfoButton, {
    showModal(modalDialog(
      tableHTML(
        describeTable(),
        rownames = FALSE,
        collapse = "separate_shiny"
      ) |>
        add_css_table(css = list("font-size", "1.2vw")) |>
        add_theme('rshiny-blue'),
      title = "Data summary:",
      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  observeEvent(input$cheatsheetButton, {
    showModal(modalDialog(
      title = "Data entry shortcuts:",
      includeMarkdown(system.file('cheatsheet.md', package = "DataEntry")),
      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  observe(on.exit(assign(
    'input',
    reactiveValuesToList(input),
    envir = .GlobalEnv
  )))

  session$allowReconnect(TRUE)
}
