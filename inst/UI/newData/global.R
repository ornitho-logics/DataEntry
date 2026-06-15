# ==========================================================================
# UI with a vertical navigation bar to enter new data
#' shiny::runApp('./inst/UI/newData', launch.browser =  TRUE)
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

package = 'DataEntry'

# Default credentials for the local test database used by this example app.
# Do not use these defaults for production deployments. Users should manage
# their own database credentials outside the package.

host = "127.0.0.1"
db = "tests"
user = "testuser"
pwd = "testuser"
tableName = "data_entry"
excludeColumns = c('pk', 'nov')
n_empty_lines = 20
authors = c('AI', 'CS', 'GS')

describeTable <- function() {
  data.frame(
    x = 'function applied on the db table',
    y = 'returning meaningful summaries'
  )
}

comments = column_comment(user, host, db, pwd, tableName, excludeColumns)

# Define UI table
uitable =
  emptyFrame(
    user,
    host,
    db,
    pwd,
    tableName,
    n = n_empty_lines,
    excludeColumns,
    preFilled = list(datetime_ = format(Sys.Date(), "%Y-%m-%d"))
  ) |>

  rhandsontable(
    afterGetColHeader = js_hot_tippy_header(comments, "description")
  ) |>

  hot_cols(columnSorting = FALSE, manualColumnResize = TRUE) |>
  hot_rows(fixedRowsTop = 1) |>
  hot_col(col = "author", type = "dropdown", source = authors)
