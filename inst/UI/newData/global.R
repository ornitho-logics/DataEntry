# UI with a vertical navigation bar to enter new data

#' devtools::load_all(".", reset = TRUE)
#' options(shiny.autoreload = TRUE)
#' shiny::runApp("./inst/UI/newData", launch.browser = TRUE)

require(DataEntry)

cnf_path = system.file("database/DataTable.cnf", package = 'DataEntry')

table_name = "data_entry"

exclude_columns = c('pk', 'nov')

n_empty_lines = 20


prefilled = list(
  datetime_ = format(Sys.Date(), "%Y-%m-%d"),
  released_time = format(Sys.time(), "%H-%M")
)

dropdowns = list(
  author = c("AI", "CS", "GS"),
  sex = c("M", "F")
)
