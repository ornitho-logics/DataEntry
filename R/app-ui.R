#' Data entry UI
#'
#' @param table_name Label shown in the data-entry menu.
#'
#' @return A Shiny UI object.
#'
#' @rdname dataentry_ui
#' @export

#' @export
ui_append_rows <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


#' @rdname dataentry_ui
#' @export
ui_edit_table <- function(table_name = "Table Name") {
  .data_entry_ui(table_name = table_name)
}


#' @rdname dataentry_ui
#' @export
ui_edit_rcode <- function(table_name = "inspectors") {
  .data_entry_ui(
    table_name = table_name,
    show_validation = FALSE
  )
}

.data_entry_ui <- function(table_name = "Table Name", show_validation = TRUE) {
  bootstrapPage(
    dataentry_deps(),

    shinycssloaders::withSpinner(
      rHandsontableOutput("table", width = "100%", height = "100vh"),
      type = 4,
      color = "#54786f",
      size = 0.7,
      hide.ui = FALSE,
      proxy.height = "100vh"
    ),

    dataentry_loading_ui(),

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
