#' Data entry 'in-browser' interfaces
#'
#' Data-entry front-end with a MariaDB backend. Flexible support for front-end data validation.
#'
#' @importFrom data.table := .I as.data.table copy data.table fwrite melt rbindlist set setDT setcolorder setnames
#' @importFrom DBI dbBegin dbCommit dbConnect dbDisconnect dbExecute dbGetQuery dbReadTable dbRollback dbWriteTable
#' @importFrom fs dir_create path
#' @importFrom glue glue
#' @importFrom htmltools HTML htmlDependency tagList tags
#' @importFrom htmlwidgets JS
#' @importFrom jsonlite toJSON
#' @importFrom praise praise
#' @importFrom RMariaDB MariaDB
#' @importFrom rhandsontable hot_col hot_cols hot_rows hot_to_r rHandsontableOutput renderRHandsontable rhandsontable
#' @importFrom shiny actionButton bootstrapPage br eventReactive hr icon
#' @importFrom shiny includeMarkdown insertUI modalDialog observeEvent reactiveVal removeUI renderUI
#' @importFrom shiny req showModal uiOutput showNotification
#' @importFrom shinyjs addClass disable runjs useShinyjs
#' @importFrom shinyWidgets actionBttn dropdown switchInput
#' @importFrom shinyjqui jqui_draggable
#' @importFrom stringr str_detect str_squish str_trunc
#' @importFrom tableHTML tableHTML
#' @importFrom ini read.ini
#' @importFrom utils globalVariables packageVersion
#' @importFrom unix eval_safe
#'
#' @keywords internal
"_PACKAGE"

globalVariables(c(
  ".",
  ".SD",
  ":=",
  "backupdir",
  "datetime_",
  "difft",
  "dropdowns",
  "dt1",
  "dt2",
  "exclude_columns",
  "invalid",
  "lq",
  "n",
  "n_empty_lines",
  "nov",
  "prefilled",
  "reason",
  "rowid",
  "set",
  "table_name",
  "tempcol",
  "time1",
  "time2",
  "uq",
  "value",
  "variable",
  "v",
  "x"
))
