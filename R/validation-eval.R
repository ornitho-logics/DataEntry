inspector_loader <- function(table_name, ...) {
  inspectors = db_get(
    "SELECT inspector FROM inspectors WHERE table_name = ? ORDER BY updated_at, table_name",
    ...,
    params = list(table_name)
  )

  if (nrow(inspectors) == 0) {
    return(function(x, ...) list())
  }

  inspector = paste0(
    "c(\n",
    paste(inspectors$inspector, collapse = ",\n"),
    "\n)"
  )

  inspector_from_text(inspector)
}


inspector_from_text <- function(inspector) {
  expr = parse(
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
      expr = expr
      x = x

      unix::eval_safe(
        eval(expr),
        timeout = 10
      )
    })
  }
}

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

# Evaluate Validators safely
evalidators <- function(L) {
  o <- try(rbindlist(L, fill = TRUE), silent = TRUE)

  if (all(c("rowid", "variable", "reason") %in% names(o))) {
    o <- o[, .(rowid = paste(rowid, collapse = ",")), by = .(variable, reason)]
  } else {
    o <- data.frame(
      rowid = NA,
      variable = NA,
      reason = "Inspector validation failed. Open the inspectors table and check the inspector definition."
    )
  }

  o
}


validation_issues <- function(x, table_name, ...) {
  inspector_loader(table_name, ...)(x) |>
    evalidators()
}


add_nov_flags <- function(x, issues) {
  x = copy(x)
  x[, nov := 0]

  if (nrow(issues) > 0) {
    x[char2vec(issues$rowid), nov := 1]
  }

  x
}
