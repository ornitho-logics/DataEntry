.data_entry_ui <- function(table_name = "Table Name") {
  bootstrapPage(
    dataentry_deps(),

    rHandsontableOutput("table", width = "100%", height = "100vh"),

    uiOutput("invalid_entries_panel"),

    ddmenu(
      tnam = table_name
    ),

    useToastr(),

    shinyjs::useShinyjs(),

    js_insertMySQLTimeStamp(),

    js_before_unload()
  )
}

#' @export
ddmenu <- function(
  tnam = "Table Name"
) {
  dropdown(
    inputId = "menu",
    circle = FALSE,
    right = FALSE,
    icon = icon("save"),
    status = "default",
    size = "sm",
    margin = "1px",
    width = "300px",
    tooltip = NULL,
    HTML(glue('<p id="TABLE_NAME">{tnam}</p>')),
    hr(),
    actionBttn(
      inputId = "saveButton",
      label = "Save",
      style = "minimal",
      block = TRUE,
      icon = icon("save")
    ),
    hr(),

    switchInput(
      inputId = "ignore_checks",
      label = "VALIDATION",
      value = FALSE,
      inline = TRUE,
      size = "large",
      width = "auto",
      offStatus = "success",
      onStatus = "danger",
      onLabel = tagList("OFF ", icon("frown")),
      offLabel = tagList("ON ", icon("smile"))
    ),

    hr(),

    actionBttn(
      inputId = "cheatsheetButton",
      label = "Keyboard shortcuts",
      style = "minimal",
      block = TRUE,
      icon = icon("keyboard")
    )
  ) |>
    tags$div(class = "dataentry-ddmenu")
}
