# UI with a vertical navigation bar to enter new data

#' devtools::load_all(".", reset = TRUE)
#' options(shiny.autoreload = TRUE)
#' shiny::runApp("./inst/UI/editData", launch.browser = TRUE)

require(DataEntry)

cnf_path = system.file("database/DataTable.cnf", package = 'DataEntry')

table_name = "data_entry"

db = ini::read.ini(cnf_path)$DataEntry$database

backupdir = tempdir()

excludeColumns = c('pk', 'nov')
