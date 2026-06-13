#' @name dropDownNavPage
#' @title shiny ui based on shinyWidgets
#' @export
#' @examples
#' if (interactive()) {
#' require(DataEntry)
#' shinyApp(
#'  ui = dropDownNavPage(),
#'  server = function(input, output) {
#'      output$table <- renderRHandsontable(
#'          rhandsontable(matrix(as.integer(NA),
#' nrow = 30, ncol = 20) |> data.table() ) )
#'  } )
#'
#'
#' }
#'

dropDownNavPage <- function(tableName = 'Table Name') {
  bootstrapPage(
    theme = NULL,

    includeCSS(system.file("style", "style.css", package = "DataEntry")),

    # HOT TABLE
    rHandsontableOutput("table", width = "100%"),

    # MENU
    tags$div(
      ddmenu(),
      style = "position: absolute; top: 0; z-index: 1000 !important;"
    ),

    # SUPPORT
    uiOutput("run_save"),

    includeScript(system.file("JS", "popper.js", package = "DataEntry")),

    includeScript(system.file("JS", "tippy.js", package = "DataEntry")),

    useToastr(),

    shinyjs::useShinyjs(),

    shinyjs::extendShinyjs(
      text = "shinyjs.js_refresh = function() { location.reload(true); }",
      functions = "js_refresh"
    ),

    js_insertMySQLTimeStamp(),

    js_before_unload()
  )
}
