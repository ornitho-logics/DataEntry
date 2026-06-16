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
#'
#' @return A data.table.
#' @export
db_get <- function(query, ...) {
	con = db_con(...)

	on.exit(DBI::dbDisconnect(con))

	DBI::dbGetQuery(con, query) |>
		data.table::as.data.table()
}

#' grand_n
#' N rows in a db table
#' @param table  db table
#' @export
grand_n <- function(table) {
	x = paste("select count(*) n from", table) |>
		db_get()
	x$n
}
