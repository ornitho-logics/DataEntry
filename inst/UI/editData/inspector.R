inspector.data_entry <- function(x, ...) {
  list(
    x[, .(author, datetime_, ID)] |>
      is.na_validator(),

    x[recapture == 0, .(sex, measure)] |>
      is.na_validator("Mandatory at first capture"),

    x[, .(datetime_)] |>
      POSIXct_validator(),

    x[, .(released_time)] |>
      hhmm_validator(),

    x[, .(sex)] |>
      is.element_validator(
        v = data.table(
          variable = "sex",
          set = list(c("M", "F"))
        )
      ),

    x[, .(measure)] |>
      interval_validator(
        v = data.table(variable = "measure", lq = 10, uq = 20),
        "Measurement out of typical range"
      )
  )
}
