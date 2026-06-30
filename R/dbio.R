#' Create a MariaDB connection
#'
#' Creates a MariaDB connection from an option file.
#'
#' If `.cnf` is `NULL`, `db_con()` first looks for `cnf_path` in the global
#' environment, then for the `DATAENTRY_CNF` environment variable.
#'
#' If `group` is `NULL`, `db_con()` first looks for `group` in the global
#' environment, then uses `"DataEntry"`.
#'
#' Once the environment variable is set, this lets
#' app-level `global.R` files set only:
#'
#' ```r
#' group = "DataEntry"
#' ```
#'
#'
#' @param .cnf Path to a MariaDB option file. If `NULL`, resolved from
#'   `cnf_path` or `DATAENTRY_CNF`.
#' @param group Option group in `.cnf`. If `NULL`, resolved from
#' global `group` or `"DataEntry"`.
#'
#' @return A MariaDB connection.
#' @export
db_con <- function(
	.cnf = NULL,
	group = NULL
) {
	if (is.null(.cnf)) {
		if (exists("cnf_path", envir = .GlobalEnv, inherits = FALSE)) {
			.cnf <- get("cnf_path", envir = .GlobalEnv)
		} else {
			.cnf <- Sys.getenv("DATAENTRY_CNF")
		}
	}

	if (!nzchar(.cnf)) {
		stop(
			"Set `cnf_path` in the global environment or DATAENTRY_CNF.",
			call. = FALSE
		)
	}

	if (is.null(group)) {
		if (exists("group", envir = .GlobalEnv, inherits = FALSE)) {
			group <- get("group", envir = .GlobalEnv)
		} else {
			group <- "DataEntry"
		}
	}

	if (!nzchar(group)) {
		stop(
			"`group` must be a non-empty string.",
			call. = FALSE
		)
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

#' @export
prepare_for_dropdown <- function(table, column) {
	x <- tryCatch(
		glue("SELECT DISTINCT {column} FROM {table}") |> db_get(),
		error = function(e) NULL
	)

	if (is.null(x) || length(x) == 0) {
		return("??")
	}

	if (is.data.frame(x)) {
		if (ncol(x) == 0 || nrow(x) == 0) {
			return("??")
		}

		x <- x[[1]]
	}

	x <- as.character(x)
	x <- x[!is.na(x) & trimws(x) != ""]

	if (length(x) == 0) {
		return("??")
	}

	x
}
