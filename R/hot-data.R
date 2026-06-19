#HOT-data

hot_safe_table <- function(x) {
  posix_cols = names(x)[
    vapply(x, inherits, logical(1), what = "POSIXt")
  ]

  if (length(posix_cols)) {
    x[,
      (posix_cols) := lapply(.SD, function(z) {
        out = format(z, "%Y-%m-%d %H:%M:%S")
        out[is.na(z)] = NA_character_
        out
      }),
      .SDcols = posix_cols
    ]
  }

  date_cols = names(x)[
    vapply(x, inherits, logical(1), what = "Date")
  ]

  if (length(date_cols)) {
    x[, (date_cols) := lapply(.SD, as.character), .SDcols = date_cols]
  }

  difftime_cols = names(x)[
    vapply(x, inherits, logical(1), what = "difftime")
  ]

  if (length(difftime_cols)) {
    x[, (difftime_cols) := lapply(.SD, as.character), .SDcols = difftime_cols]
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
  F = db_get(
    query = paste0("SELECT * from ", table, " where FALSE")
  ) |>
    hot_safe_table()

  if (!missing(exclude_columns)) {
    F = F[, setdiff(names(F), exclude_columns), with = FALSE]
  }

  if (!missing(colorder)) {
    setcolorder(F, colorder)
  }

  F = rbind(F, data.table(tempcol = rep(NA, n)), fill = TRUE)[, tempcol := NULL]

  if (!missing(preFilled)) {
    for (i in 1:length(preFilled)) {
      set(F, j = names(preFilled[i]), value = preFilled[[i]])
    }
  }

  F
}

hot_db_table <- function(table, n_empty = 10, exclude_columns = character()) {
  con = db_con()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  dat =
    DBI::dbReadTable(con, table) |>
    setDT() |>
    hot_safe_table()

  dat = dat[, setdiff(names(dat), exclude_columns), with = FALSE]

  empty_rows = as.data.frame(matrix(NA, ncol = ncol(dat), nrow = n_empty))
  names(empty_rows) = names(dat)

  rbind(dat, empty_rows)
}

drop_empty_hot_rows <- function(x) {
  x[
    !apply(x, 1, function(row) all(is.na(row) | row == "")),
  ]
}

save_from_hot <- function(input, table, drop_empty = FALSE) {
  o = hot_to_r(input$table) |>
    data.table()

  if (drop_empty) {
    o = drop_empty_hot_rows(o)
  }

  cleaner(o)
}


drop_empty_hot_rows <- function(x) {
  x[
    !apply(x, 1, function(row) all(is.na(row) | row == "")),
  ]
}


save_from_hot <- function(input, table, drop_empty = FALSE) {
  o = hot_to_r(input$table) |>
    data.table()

  if (drop_empty) {
    o = drop_empty_hot_rows(o)
  }

  cleaner(o)
}


hot_db_table <- function(table, n_empty = 10, exclude_columns = character()) {
  con = db_con()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  dat =
    DBI::dbReadTable(con, table) |>
    setDT() |>
    hot_safe_table()

  dat = dat[, setdiff(names(dat), exclude_columns), with = FALSE]

  empty_rows = as.data.frame(matrix(NA, ncol = ncol(dat), nrow = n_empty))
  names(empty_rows) = names(dat)

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
  x = if (missing(colorder)) {
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

  out =
    x |>
    rhandsontable(
      afterGetColHeader = js_hot_tippy_header(comments, "description")
    ) |>
    hot_cols(columnSorting = FALSE, manualColumnResize = TRUE) |>
    hot_rows(fixedRowsTop = 1)

  for (nm in names(dropdowns)) {
    if (nm %in% names(x)) {
      out =
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
