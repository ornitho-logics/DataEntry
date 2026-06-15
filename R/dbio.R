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
	host = get("host", envir = .GlobalEnv),
	user = get("user", envir = .GlobalEnv),
	pwd = get("pwd", envir = .GlobalEnv),
	db = get("db", envir = .GlobalEnv)
) {
	DBI::dbConnect(
		RMariaDB::MariaDB(),
		host = host,
		user = user,
		password = pwd,
		dbname = db,
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
	con = db_con()
	on.exit(dbDisconnect(con))

	dbGetQuery(con, paste0('select count(*) n from ', db, '.', table))$n
}
