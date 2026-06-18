#' Create a MariaDB connection
#'
#' Uses credentials from the global environment by default.
#'
#' @param host Database host.
#' @param user Database user.
#' @param pwd Database password.
#' @param db Database name.
#'
#' @return A MariaDB connection.
#' @export
db_con <- function(
	.cnf = get("cnf_path", envir = .GlobalEnv)
) {
	DBI::dbConnect(
		drv = RMariaDB::MariaDB(),
		default.file = .cnf,
		group = 'DataEntry'
	)
}


#' Run a MariaDB query and return a data.table
#'
#' @param query SQL query passed to `DBI::dbGetQuery()`.
#' @param ... Additional arguments passed to `db_con()`.
#' @param params Optional query parameters passed to `DBI::dbGetQuery()`.
#'
#' @return A data.table.
#' @export
db_get <- function(query, ..., params = NULL) {
	con = db_con(...)

	on.exit(DBI::dbDisconnect(con))

	if (is.null(params)) {
		x = DBI::dbGetQuery(con, query)
	} else {
		x = DBI::dbGetQuery(con, query, params = params)
	}

	x |>
		data.table::as.data.table()
}
