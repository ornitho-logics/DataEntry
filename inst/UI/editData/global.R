# ==========================================================================
# UI with a vertical navigation bar to enter new data
#' shiny::runApp('./inst/UI/editData', launch.browser =  TRUE)
# ==========================================================================

# Settings

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

# Default credentials for the local test database used by this example app.
# Do not use these defaults for production deployments. Users should manage
# their own database credentials outside the package.

host = "127.0.0.1"
db = "tests"
user = "testuser"
pwd = "testuser"
tableName = "data_entry"

backupdir = tempdir()

describeTable <- function() {
  data.frame(
    x = 'function applied on the db table',
    y = 'returning meaningful summaries'
  )
}

comments = column_comment(user, host, db, pwd, tableName)
