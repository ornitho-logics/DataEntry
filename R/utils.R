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

#' emptyFrame
#' emptyFrame used by handsontable
#' @param table            db table
#' @param n                n empty lines
#' @param excludeColumns   default 'pk'
#' @param preFilled        a named list eg. list(datetime_ = as.character(Sys.Date()))
#' @param colorder         column order. see data.table::setcolorder
#' @export
#'
emptyFrame <- function(
  table,
  n = 10,
  excludeColumns = "pk",
  preFilled,
  colorder
) {
  F = db_get(
    query = paste0("SELECT * from ", table, " where FALSE")
  ) |>
    hot_safe_table()

  if (!missing(excludeColumns)) {
    F = F[, setdiff(names(F), excludeColumns), with = FALSE]
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


#' column_comment
#' db table comments
#' @param table            db table
#' @param excludeColumns   default 'pk'
#' @return a data.frame with two fields: Column and description
#' @note this is just a convenience function around a "Select .. from information_schema" query.
#' @export
column_comment <- function(table, excludeColumns = "pk") {
  x = db_get(
    query = paste0(
      "SELECT COLUMN_NAME `Column`, COLUMN_COMMENT description FROM 
          information_schema.COLUMNS
              WHERE TABLE_SCHEMA = ",
      shQuote(db),
      " AND TABLE_NAME = ",
      shQuote(table)
    )
  )

  x[!x$Column %in% excludeColumns, ]
}


#' Cleans a data table
#' Removes NA rows, replaces 'NA' with NA
#' @param x  a data.table
#' @export
cleaner <- function(x) {
  for (j in seq_along(x)) {
    data.table::set(x, i = which(x[[j]] == 'NA'), j = j, value = NA)
  }

  for (j in seq_along(x)) {
    data.table::set(x, i = which(x[[j]] == ""), j = j, value = NA)
  }
  invisible(x)
}

#' @name char2vec
#' @title convert a list of strings to a vector
#' @param x list
#' @export
char2vec = function(x) {
  strsplit(x, ",", fixed = TRUE) |>
    unlist(use.names = FALSE) |>
    trimws() |>
    as.integer() |>
    unique()
}

#' @name praise
#' @title praises
#' @seealso [praise::praise()]
#' @export
praise <- function() {
  x <- c(
    praise::praise("Your data are ${adjective}!"),
    praise::praise("${EXCLAMATION} - ${adjective} data.")
  )

  sample(x, 1)
}


#' @name encourage
#' @title encourages
#' @export
encourage <- function() {
  x <- c(
    "Potential data entry errors."
  )

  sample(x, 1)
}


#' Save Backup of Data to CSV
#'
#' Creates a timestamped CSV backup of the provided data and saves it in a subdirectory
#' named after the database (for now: get("db", envir = .GlobalEnv) ) within the backup directory.
#'
#' @param x A data.frame or data.table containing the data to be backed up.
#' @param name The name associated to the file name
#' @param backup_dir The directory where backups are stored.
#' @param db database
#'
#' @return A character string with the full path to the backup CSV file.
#' @export
save_backup <- function(
  x,
  name,
  backup_dir,
  db = get("db", envir = .GlobalEnv)
) {
  sub_dir = fs::path(backup_dir, db)

  fs::dir_create(sub_dir, recurse = TRUE)

  backup_filename = fs::path(
    sub_dir,
    glue::glue("backup_{db}_{name}_{format(Sys.time(), '%Y%m%d_%H%M%S')}.csv")
  )

  fwrite(x, file = backup_filename)

  backup_filename
}

#' Ensure row ids
#' Add a `rowid` column if missing.
#' @param x A `data.table`.
#' @return `x`, invisibly.
#' @export
ensure_rowid <- function(x) {
  if (!"rowid" %in% names(x)) {
    x[, rowid := .I]
  }

  invisible(x)
}

#' @name meltall
#' @title melt all columns in a data.table
#' @param x  a data.table
#' @param na.rm  TRUE by default
#' @export
meltall <- function(x, na.rm = TRUE) {
  ensure_rowid(x)

  suppressWarnings(data.table::melt(
    x,
    id.vars = 'rowid',
    variable.factor = FALSE,
    value.factor = FALSE,
    na.rm = na.rm
  ))
}


#' @name strp_date_or_time
#' @title strp datetime or time (Mysql compatible)
#' @param x  strip datetime or date
#' @export
#' @examples
#' x = c(Sys.Date() |> as.character(), Sys.time()|> as.character() )
#' strp_date_or_time(x)

strp_date_or_time <- function(x) {
  s1 = strptime(x, "%Y-%m-%d %H:%M")
  s2 = strptime(x, "%Y-%m-%d")
  o = data.frame(s1, s2)

  o[is.na(o$s1), 's1'] = o[is.na(o$s1), 's2']

  as.POSIXct(o$s1)
}
