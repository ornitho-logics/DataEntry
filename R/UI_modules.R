#' @export
ddmenu <- function(
  tnam = "Table Name",
  ignore_checks = TRUE
) {
  dropdown(
    inputId = "menu",
    style = 'minimal',
    circle = FALSE,
    right = FALSE,
    status = "danger",
    icon = icon("cubes"),
    size = 'sm',
    margin = "1px",
    width = "300px",
    tooltip = NULL,

    HTML(glue('<p id="TABLE_NAME">{tnam}</p>')),

    hr(),

    actionBttn(
      inputId = "saveButton",
      label = "Save",
      style = "material-flat",
      block = TRUE,
      icon = icon("save")
    ),

    hr(),

    if (ignore_checks) {
      switchInput(
        inputId = "ignore_checks",
        label = "VALIDATION",
        value = FALSE,
        inline = TRUE,
        size = 'large',
        width = 'auto',
        offStatus = 'success',
        onStatus = 'danger',
        onLabel = paste('OFF', icon('frown')),
        offLabel = paste('ON', icon('smile'))
      )
    },

    hr(),

    actionBttn(
      inputId = "helpButton",
      label = "Columns definition",
      style = "minimal",
      block = TRUE,
      icon = icon("columns")
    ),

    br(),

    actionBttn(
      inputId = "cheatsheetButton",
      label = "Keyboard shortcuts",
      style = "minimal",
      block = TRUE,
      icon = icon("keyboard")
    )
  )
}
