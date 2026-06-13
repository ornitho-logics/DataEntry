#' @name dropDownNavPage_edit
#' @title shiny ui based on shinyWidgets
#' @export
#' @examples
#' if (interactive()) {
#' require(DataEntry)
#' shinyApp(
#'  ui = dropDownNavPage_edit(),
#'  server = function(input, output) {
#'      output$table <- renderRHandsontable(
#'          rhandsontable(matrix(as.integer(NA),
#' nrow = 30, ncol = 20) |> data.table() ) )
#'  } )
#'
#'
#' }
#'

dropDownNavPage_edit <- function(tableName = 'Table Name') {
  bootstrapPage(
    theme = NULL,

    includeCSS(system.file("style", "style.css", package = "DataEntry")),

    # HOT TABLE

    rHandsontableOutput("table", width = "100%"),

    # MENU

    tags$div(
      ddmenu(ignore_checks = FALSE, tableInfoButton = FALSE),
      style = "position: absolute; top: 0; z-index: 1000 !important;"
    ),

    # SUPPORT
    uiOutput("run_save"),

    includeScript(system.file("JS", "popper.js", package = "DataEntry")),

    includeScript(system.file("JS", "tippy.js", package = "DataEntry")),

    useToastr(),

    js_insertMySQLTimeStamp(),

    js_before_unload()
  )
}
