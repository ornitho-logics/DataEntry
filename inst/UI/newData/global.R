# UI with a vertical navigation bar to enter new data

#' shiny::runApp('./inst/UI/newData', launch.browser =  TRUE)

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

options(shiny.autoreload = TRUE)

cnf_path = system.file("database/DataTable.cnf", package = 'DataEntry')

tableName = "data_entry"

excludeColumns = c('pk', 'nov')

n_empty_lines = 20

authors = c('AI', 'CS', 'GS')

comments = column_comment(tableName, excludeColumns)


# Define UI table
uitable =
  emptyFrame(
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
