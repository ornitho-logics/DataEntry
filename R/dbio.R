#' Create a MariaDB connection
#'
#' Creates a MariaDB connection from an option file.
#'
#' The option file is searched in this order:
#'
#' 1. `Sys.getenv("DATAENTRY_CNF")`
#' 2. `cnf_path` from the global environment
#' 3. `~/.my.cnf`
#'
#' The option group is searched in this order:
#'
#' 1. `Sys.getenv("DATAENTRY_GROUP")`
#' 2. `cnf_group` from the global environment
#' 3. `"DataEntry"`
#'
#' The option file should contain the selected group with connection fields
#' understood by `RMariaDB::MariaDB()`, for example `host`, `user`,
#' `password`, and `database`.
#'
#' @param .cnf Path to a MariaDB option file.
#' @param group Option group in `.cnf`.
#'
#' @return A MariaDB connection.
#' @export
db_con <- function(
	.cnf = NULL,
	group = NULL
) {
	if (is.null(.cnf)) {
		.cnf <- Sys.getenv("DATAENTRY_CNF")

		if (
			!nzchar(.cnf) && exists("cnf_path", envir = .GlobalEnv, inherits = TRUE)
		) {
			.cnf <- get("cnf_path", envir = .GlobalEnv)
		}

		if (!nzchar(.cnf)) {
			.cnf <- "~/.my.cnf"
		}
	}

	if (is.null(group)) {
		group <- Sys.getenv("DATAENTRY_GROUP")

		if (
			!nzchar(group) && exists("cnf_group", envir = .GlobalEnv, inherits = TRUE)
		) {
			group <- get("cnf_group", envir = .GlobalEnv)
		}

		if (!nzchar(group)) {
			group <- "DataEntry"
		}
	}

	DBI::dbConnect(
		drv = RMariaDB::MariaDB(),
		default.file = path.expand(.cnf),
		group = group
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
