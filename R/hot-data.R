#HOT-data

hot_safe_table <- function(x) {
  posix_cols <- names(x)[
    vapply(x, inherits, logical(1), what = "POSIXt")
  ]

  for (col in posix_cols) {
    z <- x[[col]]
    out <- format(z, "%Y-%m-%d %H:%M:%S")
    out[is.na(z)] <- NA_character_
    set(x, j = col, value = out)
  }

  date_cols <- names(x)[
    vapply(x, inherits, logical(1), what = "Date")
  ]

  for (col in date_cols) {
    set(x, j = col, value = as.character(x[[col]]))
  }

  difftime_cols <- names(x)[
    vapply(x, inherits, logical(1), what = "difftime")
  ]

  for (col in difftime_cols) {
    z <- x[[col]]

    out <- if (length(z) == 0) {
      character()
    } else {
      as.character(z)
    }

    out[is.na(z)] <- NA_character_

    set(x, j = col, value = out)
  }

  x
}

emptyFrame <- function(
  table,
  n = 10,
  exclude_columns = "pk",
  preFilled,
  colorder
) {
  F <- db_get(
    query = paste0("SELECT * from ", table, " where FALSE")
  ) |>
    hot_safe_table()

  if (!missing(exclude_columns)) {
    F <- F[, setdiff(names(F), exclude_columns), with = FALSE]
  }

  if (!missing(colorder)) {
    setcolorder(F, colorder)
  }

  F <- rbind(F, data.table(tempcol = rep(NA, n)), fill = TRUE)[,
    tempcol := NULL
  ]

  if (!missing(preFilled) && length(preFilled) > 0) {
    for (nm in names(preFilled)) {
      set(F, j = nm, value = preFilled[[nm]])
    }
  }

  F
}

hot_db_table <- function(table, n_empty = 10, exclude_columns = character()) {
  con <- db_con()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  dat <-
    DBI::dbReadTable(con, table) |>
    setDT() |>
    hot_safe_table()

  dat <- dat[, setdiff(names(dat), exclude_columns), with = FALSE]

  empty_rows <- as.data.frame(matrix(NA, ncol = ncol(dat), nrow = n_empty))
  names(empty_rows) <- names(dat)

  rbind(dat, empty_rows)
}


save_from_hot <- function(input, table, drop_empty = FALSE) {
  o <- hot_to_r(input$table) |>
    data.table()

  if (drop_empty) {
    o <- drop_empty_hot_rows(o)
  }

  cleaner(o)
}


drop_empty_hot_rows <- function(x) {
  if (nrow(x) == 0L || ncol(x) == 0L) {
    return(x)
  }

  keep <- Reduce(
    `|`,
    lapply(x, function(z) {
      if (is.character(z)) {
        !is.na(z) & nzchar(z)
      } else {
        !is.na(z)
      }
    })
  )

  x[keep]
}


save_from_hot <- function(input, table, drop_empty = FALSE) {
  o <- hot_to_r(input$table) |>
    data.table()

  if (drop_empty) {
    o <- drop_empty_hot_rows(o)
  }

  cleaner(o)
}


hot_db_table <- function(table, n_empty = 10, exclude_columns = character()) {
  con <- db_con()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  dat <-
    DBI::dbReadTable(con, table) |>
    setDT() |>
    hot_safe_table()

  dat <- dat[, setdiff(names(dat), exclude_columns), with = FALSE]

  empty_rows <- as.data.frame(matrix(NA, ncol = ncol(dat), nrow = n_empty))
  names(empty_rows) <- names(dat)

  rbind(dat, empty_rows)
}


# HOT-render
hot_append_table <- function(
  table,
  n_empty,
  exclude_columns = character(),
  comments,
  pre_filled = list(),
  colorder,
  dropdowns = list()
) {
  x <- if (missing(colorder)) {
    emptyFrame(
      table = table,
      n = n_empty,
      exclude_columns = exclude_columns,
      preFilled = pre_filled
    )
  } else {
    emptyFrame(
      table = table,
      n = n_empty,
      exclude_columns = exclude_columns,
      preFilled = pre_filled,
      colorder = colorder
    )
  }

  out <-
    x |>
    rhandsontable(
      enterMoves = list(row = 1, col = 0),
      afterGetColHeader = js_hot_tippy_header(comments, "description")
    ) |>
    hot_cols(
      columnSorting = FALSE,
      colWidths = 120,
      manualColumnResize = TRUE,
      autoColumnSize = FALSE
    ) |>
    hot_rows(fixedRowsTop = 1)

  for (nm in names(dropdowns)) {
    if (nm %in% names(x)) {
      out <-
        out |>
        hot_col(
          col = nm,
          type = "autocomplete",
          source = dropdowns[[nm]]
        )
    }
  }

  out
}
