# UI with a vertical navigation bar to enter new data

#' ii = function() {
#' devtools::load_all(".", reset = TRUE)
#' options(shiny.autoreload = TRUE)
#' shiny::runApp("./inst/UI/editInspector", launch.browser = TRUE) }

require(DataEntry)

cnf_path = system.file("database/DataTable.cnf", package = 'DataEntry')

db = ini::read.ini(cnf_path)$DataEntry$database

backupdir = tempdir()

n_empty_lines = 2

exclude_columns = "updated_at"

code_column = "inspector"

table_name = "inspectors"

code_column_width = 760

code_row_height = 100
