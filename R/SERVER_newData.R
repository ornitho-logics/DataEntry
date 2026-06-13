#' Shiny server function
#'
#' @param input     Shiny server
#' @param output    Shiny server
#' @param session   Shiny server
#'
#' @export
#' @note user,host,db,pwd, uitable, comments, describeTable, getDataSummary are hardwired and should be defined in global.R
#'       inspectors are loaded with  [DataEntry.validation::inspector_loader()]
#'
server_newData_dropDownNavPage <- function(input, output, session) {
  # Settings
  # Is no-validation column present in table ?
  con = dbConnect(
    RMySQL::MySQL(),
    host = host,
    user = user,
    db = db,
    password = pwd
  )
  hasnov = dbGetQuery(
    con,
    glue::glue("SHOW COLUMNS FROM {tableName} LIKE 'nov';")
  ) |>
    nrow() >
    0

  dbDisconnect(con)

  observeEvent(input$refresh, {
    # defined below
    shinyjs::js$js_refresh()
  })

  Save <- eventReactive(input$saveButton, {
    o = hot_to_r(input$table) |> data.table()
    cleaner(o)
    class(o) = c(class(o), tableName) # inspector() uses S3

    DataEntry.validation::inspector_loader(path = "inspector.R")

    o
  })

  # VALIDATE - SAVE

  output$run_save <- renderUI({
    isolate(ignore_validators <- input$ignore_checks)
    isolate(is_invalid <- input$invalidButton)

    x = Save()

    # Data validation

    cc = inspector(x) |> evalidators()
    # assign('cc', cc , envir = .GlobalEnv)

    # errors
    if (nrow(cc) > 0 && !ignore_validators) {
      toastr_error(
        message = HTML(
          "<strong>To identify issues, click the <kbd>Data Entry Issues</kbd> button, correct the entries, and try again.</strong>"
        ),
        title = HTML(glue("<h3>{encourage()}</h3>")),
        timeOut = 10000,
        closeButton = TRUE,
        position = "top-center"
      )

      if (is.null(is_invalid)) {
        insertUI(
          selector = "#saveButton",
          where = "afterEnd",
          ui = list(
            br(),
            actionBttn(
              inputId = "invalidButton",
              label = "Data entry issues",
              style = "material-flat",
              color = "danger",
              block = TRUE,
              icon = icon("bomb")
            )
          )
        )
      }
    }

    # Database update
    if (nrow(cc) == 0 | (nrow(cc) > 0 & ignore_validators)) {
      # add no-validation info to table
      if (hasnov) {
        x = copy(x)
        x[, nov := as.integer(0)]
        x[char2vec(cc$rowid) |> as.integer(), nov := 1L]
      }

      con = dbConnect(
        RMySQL::MySQL(),
        host = host,
        user = user,
        db = db,
        password = pwd
      )
      saved_set = dbWriteTable(
        con,
        tableName,
        x,
        append = TRUE,
        row.names = FALSE
      )
      dbDisconnect(con)

      if (saved_set) {
        shinyjs::disable("saveButton")
        shinyjs::runjs('$("#saveButton").css("background-color","grey");')

        msg = if (ignore_validators) {
          "I bet you brushed off that validation for a good reason!"
        } else {
          glue("   <h4> {praise()} </h4>    ")
        }

        toastr_success(
          title = "",
          message = msg,
          timeOut = 20000,
          position = 'top-center'
        )

        # assign('x', x, .GlobalEnv)

        # feedback msg
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
              icon = icon("kiwi-bird")
            ),

            #HTML(msg)

            HTML(glue(
              '<p style =" 
                  color:#345678;
                  font-size: 2.1em;
                  text-align: center;

                  "> 
                {msgau}
              </p>

              '
            ))
          )
        )

        removeUI("#ignore_checks")
        removeUI("#helpButton")
        removeUI("#cheatsheetButton")
        removeUI("#tableInfoButton")
      }

      cat('-------')
    }
  })

  # HOT TABLE
  output$table <- renderRHandsontable({
    data = uitable
  })

  # Show INVALID data
  observeEvent(input$invalidButton, {
    showModal(modalDialog(
      title = "Invalid entries:",

      tableHTML(
        Save() |> inspector() |> evalidators(),
        rownames = FALSE,
        collapse = "separate_shiny"
      ) |>
        add_theme('rshiny-blue'),

      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  # Show column DEFINITIONS
  observeEvent(input$helpButton, {
    showModal(modalDialog(
      tableHTML(comments, rownames = FALSE, collapse = "separate_shiny") |>
        add_css_table(css = list("font-size", "1.2vw")) |>
        add_theme('rshiny-blue'),

      title = "Columns definition:",
      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  # Show data SUMMARY
  observeEvent(input$tableInfoButton, {
    x = describeTable()

    showModal(
      modalDialog(
        tableHTML(
          x,
          rownames = FALSE,
          collapse = "separate_shiny",
          escape = FALSE
        ) |>
          add_css_table(css = list("font-size", "1.2vw")) |>
          add_theme('rshiny-blue'),

        title = "Data summary:",
        easyClose = TRUE,
        footer = NULL,
        size = 'l'
      )
    )
  })

  # Show CHEATSHEET
  observeEvent(input$cheatsheetButton, {
    showModal(modalDialog(
      title = "Data entry shortcuts:",
      includeMarkdown(system.file('cheatsheet.md', package = "DataEntry")),
      easyClose = TRUE,
      footer = NULL,
      size = 'l'
    ))
  })

  # observe( on.exit( assign('input', reactiveValuesToList(input) , envir = .GlobalEnv)) )

  session$allowReconnect(TRUE)
}
