#' @name dropDownNavPage
#' @title shiny ui based on shinyWidgets
#' @export
#'
dropDownNavPage <- function(tableName = 'Table Name') {
  fillPage(
    bootstrap = FALSE,

    dataentry_deps(),

    # HOT TABLE
    rHandsontableOutput("table", width = "100%"),

    # MENU
    tags$div(
      ddmenu(),
      style = "position: absolute; top: 0; z-index: 1000 !important;"
    ),

    # SUPPORT
    uiOutput("run_save"),

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
