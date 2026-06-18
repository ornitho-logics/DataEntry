#' @export
ui_append_rows <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


#' @export
ui_edit_table <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


.data_entry_ui <- function(table_name = "Table Name") {
  bootstrapPage(
    dataentry_deps(),

    rHandsontableOutput("table", width = "100%", height = "100vh"),

    uiOutput("invalid_entries_panel"),

    ddmenu(
      tnam = table_name
    ),

    shinyjs::useShinyjs(),

    js_insertMySQLTimeStamp(),

    js_before_unload()
  )
}
