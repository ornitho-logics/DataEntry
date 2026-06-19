app_global <- function(
  name,
  default,
  env = parent.frame(),
  required = missing(default)
) {
  if (!exists(name, envir = env, inherits = TRUE)) {
    if (isTRUE(required)) {
      stop(
        "Required app global `",
        name,
        "` is not defined.",
        call. = FALSE
      )
    }

    if (missing(default)) {
      return(NULL)
    }

    return(default)
  }

  get(name, envir = env, inherits = TRUE)
}
