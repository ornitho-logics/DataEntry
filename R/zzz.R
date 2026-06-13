#' Data entry 'in-browser' interfaces
#'
#' Data-entry front-end; MySQL/MariaDB backend. Flexible support for front-end data validation.
#'
#' @keywords internal
"_PACKAGE"


.onAttach <- function(libname, pkgname) {
    dcf <- read.dcf(file = system.file('DESCRIPTION', package = pkgname))
    packageStartupMessage(paste('This is', pkgname, dcf[, 'Version']))

    # see ./inst/install_testdb.sql
    options(DataEntry.host = "127.0.0.1")
    options(DataEntry.db = "tests")
    options(DataEntry.user = 'testuser')
    options(DataEntry.pwd = 'testuser')
    options(DataEntry.backupdir = '~/DataEntryBackup')
}


# no visible global function definitions
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
    'describeTable',
    'dbExecute'
))


#' @import methods  RMySQL data.table rhandsontable shiny glue stringr shinydashboard shinytoastr shinyWidgets tableHTML praise  DataEntry.validation
NULL


#' @importFrom shinyjs useShinyjs extendShinyjs
NULL


#' @importFrom grDevices colorRampPalette
NULL

#' @importFrom fs dir_create path
NULL
