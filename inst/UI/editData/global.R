# UI with a vertical navigation bar to enter new data
#' shiny::runApp('./inst/UI/editData', launch.browser =  TRUE)

sapply(
  c(
    'DataEntry',
    'DataEntry.validation',
    'shinyjs',
    'shinyWidgets',
    'glue',
    'tableHTML',
    'shinytoastr'
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)
tags = shiny::tags

cnf_path = system.file("database/DataTable.cnf", package = 'DataEntry')

tableName = "data_entry"

backupdir = tempdir()

comments = column_comment(tableName)
