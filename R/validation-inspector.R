#' Inspector loader
#'
#' @param table_name Database table name.
#' @param ... Additional arguments passed to [db_get()].
#'
#' @return A function with signature `function(x, ...)`.
#' @export
inspector_loader <- function(table_name, ...) {
  db_get(
    "SELECT inspector FROM inspectors WHERE table_name = ? LIMIT 1",
    ...,
    params = list(table_name)
  )[,
    inspector_from_text(inspector[[1]])
  ]
}


inspector_from_text <- function(inspector) {
  expr = parse(text = inspector)[[1]]

  function(x, ...) {
    eval(expr)
  }
}
