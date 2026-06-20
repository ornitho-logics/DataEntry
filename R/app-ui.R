#' @export
ui_append_rows <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


#' @export
ui_edit_table <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


#' @export
ui_edit_inspectors <- function(table_name = "inspectors") {
  .data_entry_ui(
    table_name = table_name,
    show_validation = FALSE
  )
}

.data_entry_ui <- function(table_name = "Table Name", show_validation = TRUE) {
  bootstrapPage(
    dataentry_deps(),

    rHandsontableOutput("table", width = "100%", height = "100vh"),

    uiOutput("invalid_entries_panel"),

    ddmenu(
      tnam = table_name,
      show_validation = show_validation
    ),

    shinyjs::useShinyjs(),

    js_insertMySQLTimeStamp(),

    js_ctrl_s_open_ddmenu(),

    js_before_unload()
  )
}
