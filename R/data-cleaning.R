cleaner <- function(x) {
  for (j in seq_along(x)) {
    data.table::set(x, i = which(x[[j]] == "NA"), j = j, value = NA)
  }

  for (j in seq_along(x)) {
    data.table::set(x, i = which(x[[j]] == ""), j = j, value = NA)
  }
  invisible(x)
}

strp_date_or_time <- function(x) {
  s1 = strptime(x, "%Y-%m-%d %H:%M")
  s2 = strptime(x, "%Y-%m-%d")
  o = data.frame(s1, s2)

  o[is.na(o$s1), 's1'] = o[is.na(o$s1), 's2']

  as.POSIXct(o$s1)
}

char2vec <- function(x) {
  strsplit(x, ",", fixed = TRUE) |>
    unlist(use.names = FALSE) |>
    trimws() |>
    as.integer() |>
    unique()
}

ensure_rowid <- function(x) {
  if (!"rowid" %in% names(x)) {
    x[, rowid := .I]
  }

  invisible(x)
}

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

praise <- function() {
  x <- c(
    praise::praise("Your data are ${adjective}!"),
    praise::praise("${EXCLAMATION} - ${adjective} data.")
  )

  sample(x, 1)
}
