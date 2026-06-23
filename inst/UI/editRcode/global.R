# UI with a vertical navigation bar to enter new data

#' aa = function() {
#' devtools::load_all(".", reset = TRUE)
#' options(shiny.autoreload = TRUE)
#' shiny::runApp("./inst/UI/editRcode", launch.browser = TRUE) }

require(DataEntry)

cnf_path <- system.file("database/DataTable.cnf", package = 'DataEntry')

backupdir <- tempdir()

n_empty_lines <- 2

exclude_columns <- "updated_at"

table_name <- "artifacts"
code_column <- "artifact"
id_column <- "artifact_name"

code_column_width <- 760

code_row_height <- 100
