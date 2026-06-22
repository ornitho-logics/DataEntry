inspector_loader <- function(table_name, ...) {
  if (!inspectors_table_exists()) {
    if (!is.null(shiny::getDefaultReactiveDomain())) {
      showNotification(
        ui = "The inspectors table is missing. Validation was skipped.",
        type = "warning",
        duration = 8,
        closeButton = TRUE
      )
    }

    return(function(x, ...) list())
  }

  inspectors <- db_get(
    "SELECT inspector FROM inspectors WHERE table_name = ? ORDER BY updated_at, table_name",
    ...,
    params = list(table_name)
  )

  if (nrow(inspectors) == 0) {
    return(function(x, ...) list())
  }

  inspector <- paste0(
    "c(\n",
    paste(inspectors$inspector, collapse = ",\n"),
    "\n)"
  )

  inspector_from_text(inspector)
}


inspector_from_text <- function(inspector) {
  expr <- parse(
    text = inspector,
    keep.source = FALSE
  )

  if (length(expr) != 1) {
    stop(
      "Inspector must contain exactly one R expression.",
      call. = FALSE
    )
  }

  force(expr)

  function(x, ...) {
    local({
      expr <- expr
      x <- x

      unix::eval_safe(
        eval(expr),
        timeout = 10
      )
    })
  }
}


#' Evaluate a validator safely
#'
#' `try_validator()` evaluates a validator call and always returns a
#' validator-shaped object. If the validator errors, or if it returns an object
#' that does not contain `rowid`, `variable`, and `reason`, the error is
#' converted to a single validation issue.
#'
#' This is useful inside inspectors, where one broken validator should be
#' reported to the user instead of stopping the whole validation step.
#'
#' @param ... A validator expression to evaluate.
#' @param nam A short name used in the error message if the validator fails.
#'
#' @return A `data.frame`, `data.table`, or similar object with at least
#'   `rowid`, `variable`, and `reason`.
#'
#' @examples
#' x = data.table::data.table(a = c(1, NA))
#'
#' try_validator(
#'   is.na_validator(x),
#'   nam = "mandatory"
#' )
#'
#' try_validator(
#'   stop("broken validator"),
#'   nam = "broken"
#' )
#'
#' @export
try_validator <- function(..., nam = "") {
  ev <- try(..., silent = TRUE)

  if (inherits(ev, "try-error")) {
    o <- data.frame(
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
    o <- ev
  }

  o
}

#' Combine validator outputs
#'
#' `evalidators()` combines the output of several validators into the format
#' used by DataEntry inspectors. Rows with the same `variable` and `reason` are
#' grouped together, and their `rowid` values are collapsed into a comma-separated
#' string.
#'
#' If the validator outputs cannot be combined, `evalidators()` returns a
#' validator-shaped error explaining that the inspector failed.
#'
#' @param L A list of validator outputs. Each element should contain at least
#'   `rowid`, `variable`, and `reason`.
#'
#' @param msg Fallback validation message used when validator outputs cannot be
#'   combined or do not contain `rowid`, `variable`, and `reason`.
#'
#' @return A `data.table` with columns `variable`, `reason`, and `rowid` when
#'   validation succeeds. If validation fails, a `data.frame` with `rowid`,
#'   `variable`, and `reason`.
#'
#' @examples
#' L = list(
#'   data.table::data.table(rowid = c(1, 2), variable = "a", reason = "missing"),
#'   data.table::data.table(rowid = 3, variable = "a", reason = "missing"),
#'   data.table::data.table(rowid = 2, variable = "b", reason = "invalid")
#' )
#'
#' evalidators(L)
#'
#' @export
evalidators <- function(
  L,
  msg = "Inspector validation failed. Open the inspectors table and check the inspector definition."
) {
  o <- try(rbindlist(L, fill = TRUE), silent = TRUE)

  if (all(c("rowid", "variable", "reason") %in% names(o))) {
    o <- o[, .(rowid = paste(rowid, collapse = ",")), by = .(variable, reason)]
  } else {
    o <- data.frame(
      rowid = NA,
      variable = NA,
      reason = msg
    )
  }

  o
}


validation_issues <- function(x, table_name, ...) {
  inspector_loader(table_name, ...)(x) |>
    evalidators()
}


add_nov_flags <- function(x, issues) {
  x <- copy(x)
  x[, nov := 0]

  if (nrow(issues) > 0) {
    x[char2vec(issues$rowid), nov := 1]
  }

  x
}
