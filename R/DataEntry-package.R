#' Data entry 'in-browser' interfaces
#'
#' Data-entry front-end with a MariaDB backend. Flexible support for front-end data validation.
#'
#' @import methods RMariaDB data.table glue stringr
#'
#' @import rhandsontable shiny shinydashboard shinytoastr shinyWidgets tableHTML praise
#'
#' @importFrom shinyjs useShinyjs extendShinyjs
#'
#' @importFrom grDevices colorRampPalette
#'
#' @importFrom fs dir_create path
#'
#' @keywords internal
"_PACKAGE"


utils::globalVariables(c(
  '.',
  ':=',
  'Column',
  'comments',
  'datetime_',
  'db',
  'host',
  'LL',
  'lq',
  'LR',
  'nov',
  'n',
  'pwd',
  'recapture',
  'tableName',
  'tempcol',
  'uitable',
  'UL',
  'uq',
  'UR',
  'user',
  'value',
  'variable',
  'v',
  'w',
  'dbGetQuery',
  'describeTable'
))
