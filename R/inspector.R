#' Let a validator fail without an error
#' @param  x an expression that should tipically return a validator result but in some,
#'           yet to be discovered, exceptional cases, it does not.
#' @param nam an optional name to help identify the failty validator later.
#' @export
#' @examples
#' x = data.table(id = 1:10)
#' wrong_output_validator <- nrow
#' faulty_validator <- function(x) foo(x)
#'
#' faulty_validator (x) |> try_validator(nam = 'foo')
#' nrow(x) |> try_validator()
#'
try_validator <- function(..., nam = "") {
  ev = try(..., silent = TRUE)

  if (inherits(ev, "try-error")) {
    o = data.frame(
      rowid = as.character(NA),
      variable = as.character(NA),
      reason = glue(
        "Validator {dQuote(nam)} returned an error: {str_trunc(ev, 30)}"
      ) |>
        as.character()
    )
  } else if (!all(c("rowid", "variable", "reason") %in% names(ev))) {
    o <- data.frame(
      rowid = as.character(NA),
      variable = as.character(NA),
      reason = glue(
        "Validator {dQuote(nam)} seem to work but it does not return the correct format. "
      ) |>
        str_squish() |>
        as.character()
    )
  } else {
    o = ev
  }

  o
}


#' Evaluate Validators safely
#' @param  L A list resulting from combining several validators
#' @export
evalidators <- function(L) {
  o <- try(rbindlist(L, fill = TRUE), silent = TRUE)

  if (all(c("rowid", "variable", "reason") %in% names(o))) {
    o <- o[, .(rowid = paste(rowid, collapse = ",")), by = .(variable, reason)]
  } else {
    o <- data.frame(
      rowid = NA,
      variable = NA,
      reason = glue(
        "Oops! validators need validation, Error: {dQuote( str_squish(o))}"
      )
    )
  }

  o
}


#' Data police
#'
#' Inspectors are S3 functions that usually return the results of several validators
#'
#' @title   data inspector
#' @param   x a data.table with its (S3) class extended by the database table name (see server.R)
#' @export
#'
#' @examples
#' require(data.table)
#' require(DataEntry.validation)
#' x <- data.table(
#'   v1        = c(NA, NA, as.character(Sys.time() - 3600 * 24 * 10)),
#'   datetime_ = c("2016-11-23 25:23", as.character(Sys.time() - 100), as.character(Sys.time() + 100))
#' )
#' x[, rowid := .I]
#' class(x) <- c(class(x), "tablex")
#'
#' inspector.tablex <- function(x) {
#'   list(
#'     # first validator
#'     x[, .(datetime_)] |> POSIXct_validator()
#'     ,
#'     # second validator
#'     is.na_validator(x)
#'     ,
#'     # faulty validator
#'     nrow(x) |> try_validator(nam = 'wrong output')
#'
#'   )
#'
#'
#' }
#'
#' inspector(x) |> evalidators()
#'
inspector <- function(x) {
  UseMethod("inspector", x)
}

#' @export
inspector.default <- function(x) {
  data.frame(
    rowid = NA,
    variable = NA,
    reason = "Validators are not available for this table!"
  )
}


#' @title   Inspector loader
#' @description Loads inspectors from a file.
#' @param path The path to the files containing the inspector functions.
#' @note This function is just sourcing the file but it does not return an error when something goes wrong.
#' @export
#' @examples
#' p <- system.file("inspectors", "DataEntry.R", package = "DataEntry.validation")
#' inspector_loader(p)
#'
inspector_loader <- function(path) {
  o <- try(source(path, local = .GlobalEnv), silent = TRUE)

  if (inherits(o, "try-error")) {
    warning("Could not source", basename(path), "in .GlobalEnv")
  }
}
