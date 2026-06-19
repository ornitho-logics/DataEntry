inspector_loader <- function(table_name, ...) {
  db_get(
    "SELECT inspector FROM inspectors WHERE table_name = ? LIMIT 1",
    ...,
    params = list(table_name)
  )[,
    inspector_from_text(inspector[[1]])
  ]
}


inspector_env <- function(x) {
  env = new.env(parent = asNamespace("DataEntry"))

  env$x = x

  env$db_con = function(...) {
    db_con(...)
  }

  env$db_get = function(query, ..., params = NULL) {
    db_get(
      query,
      ...,
      params = params
    )
  }

  env
}

inspector_from_text <- function(inspector) {
  expr = parse(
    text = inspector,
    keep.source = FALSE
  )

  if (length(expr) != 1L) {
    stop(
      "Inspector must contain exactly one R expression.",
      call. = FALSE
    )
  }

  expr = expr[[1L]]

  check_inspector_expr(expr)

  force(expr)

  function(x, ...) {
    unix::eval_safe(
      eval(
        expr,
        envir = inspector_env(x)
      ),
      timeout = 5L,
      closeAllConnections = TRUE,
      rlimits = list(
        as = 512 * 1024^2,
        cpu = 5L,
        fsize = 10 * 1024^2,
        nproc = 16L,
        nofile = 64L,
        core = 0L
      )
    )
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
