app_global <- function(
  name,
  default,
  env = parent.frame(),
  required = missing(default)
) {
  if (exists(name, envir = env, inherits = TRUE)) {
    return(get(name, envir = env, inherits = TRUE))
  }

  if (exists(name, envir = .GlobalEnv, inherits = TRUE)) {
    return(get(name, envir = .GlobalEnv, inherits = TRUE))
  }

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

  default
}
