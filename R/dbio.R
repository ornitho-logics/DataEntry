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
	con <- db_con(...)

	on.exit(DBI::dbDisconnect(con))

	if (is.null(params)) {
		x <- DBI::dbGetQuery(con, query)
	} else {
		x <- DBI::dbGetQuery(con, query, params = params)
	}

	x |>
		data.table::as.data.table()
}


replace_db_table <- function(x, table_name, backupdir) {
	bk_path <- save_backup(
		x,
		table_name,
		backup_dir = backupdir
	)

	message("DataEntry backup written to: ", bk_path)

	con <- db_con()
	on.exit(DBI::dbDisconnect(con), add = TRUE)

	in_transaction <- FALSE

	tryCatch(
		{
			DBI::dbBegin(con)
			in_transaction <- TRUE

			DBI::dbExecute(
				con,
				paste("DELETE FROM", DBI::dbQuoteIdentifier(con, table_name))
			)

			DBI::dbWriteTable(
				con,
				table_name,
				x,
				append = TRUE,
				row.names = FALSE
			)

			DBI::dbCommit(con)
			in_transaction <- FALSE

			bk_path
		},
		error = function(e) {
			if (isTRUE(in_transaction)) {
				try(DBI::dbRollback(con), silent = TRUE)
			}

			message("DataEntry save failed: ", conditionMessage(e))
			FALSE
		}
	)
}


inspectors_table_exists <- function() {
	tryCatch(
		{
			db_get("SHOW TABLES LIKE 'inspectors'") |>
				nrow() >
				0
		},
		error = function(e) FALSE
	)
}
