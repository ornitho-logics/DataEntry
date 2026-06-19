ddmenu <- function(
  tnam = "Table Name"
) {
  dropdown(
    inputId = "menu",
    circle = FALSE,
    right = FALSE,
    icon = icon("save"),
    status = "default",
    size = "sm",
    margin = "1px",
    width = "300px",
    tooltip = NULL,
    HTML(glue('<p id="TABLE_NAME">{tnam}</p>')),
    hr(),
    actionBttn(
      inputId = "saveButton",
      label = "Save",
      style = "minimal",
      block = TRUE,
      icon = icon("save")
    ),
    hr(),

    switchInput(
      inputId = "ignore_checks",
      label = "VALIDATION",
      value = FALSE,
      inline = TRUE,
      size = "large",
      width = "auto",
      offStatus = "success",
      onStatus = "danger",
      onLabel = tagList("OFF ", icon("frown")),
      offLabel = tagList("ON ", icon("smile"))
    ),

    hr(),

    actionBttn(
      inputId = "cheatsheetButton",
      label = "Keyboard shortcuts",
      style = "minimal",
      block = TRUE,
      icon = icon("keyboard")
    )
  ) |>
    tags$div(class = "dataentry-ddmenu")
}

dataentry_deps <- function() {
  htmltools::tagList(
    htmltools::tags$head(
      htmltools::tags$link(
        rel = "preconnect",
        href = "https://fonts.googleapis.com"
      ),
      htmltools::tags$link(
        rel = "preconnect",
        href = "https://fonts.gstatic.com",
        crossorigin = NA
      ),
      htmltools::tags$link(
        rel = "stylesheet",
        href = "https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap"
      )
    ),

    htmltools::htmlDependency(
      name = "popper",
      version = "2.11.8",
      src = c(file = "JS"),
      script = "popper.js",
      package = "DataEntry"
    ),

    htmltools::htmlDependency(
      name = "tippy",
      version = "6.3.7",
      src = c(file = "JS"),
      script = "tippy.js",
      package = "DataEntry"
    ),

    htmltools::htmlDependency(
      name = "dataentry-style",
      version = as.character(packageVersion("DataEntry")),
      src = c(file = "style"),
      stylesheet = "style.css",
      package = "DataEntry"
    ),

    htmltools::htmlDependency(
      name = "dataentry-code-cell-renderer",
      version = as.character(packageVersion("DataEntry")),
      src = c(file = "JS"),
      script = "code-cell-renderer.js",
      package = "DataEntry"
    )
  )
}


# notifications
dataentry_notif <- function(msg, type = "message", duration = 20) {
  showNotification(
    ui = HTML(msg),
    type = type,
    duration = duration,
    closeButton = TRUE
  )
}

updated_table_feedback <- function(bk_path, ...) {
  msg = glue(
    'Table saved!<br>
    Backup stored as <br>
    <code>{bk_path |> basename()}</code>.'
  )

  dataentry_notif(msg = msg, ...)
}

appended_rows_feedback <- function(x, ignore = TRUE, ...) {
  msg = if (ignore) {
    glue(
      "
    <h4>
    You probably had your reasons for skipping validation!
    Anyway, {nrow(x)} rows made it to the DB.
    <span class='dataentry-notification-emoji'>&#128530;</span>
    </h4>
    "
    )
  } else {
    glue(
      "
    <h4>
    {praise()}
    <span class='dataentry-notification-emoji'>&#x2726;&#x2726;&#x2726;&#x2726;&#x2726;</span>
    <br>
    You saved {nrow(x)} rows to the DB.
    </h4>
    "
    )
  }

  dataentry_notif(msg = msg, ...)
}


save_backup <- function(
  x,
  name,
  backup_dir,
  db = get("db", envir = .GlobalEnv)
) {
  sub_dir = fs::path(backup_dir, db)

  fs::dir_create(sub_dir, recurse = TRUE)

  backup_filename = fs::path(
    sub_dir,
    glue::glue("backup_{db}_{name}_{format(Sys.time(), '%Y%m%d_%H%M%S')}.csv")
  )

  fwrite(x, file = backup_filename)

  backup_filename
}


table_has_nov <- function(table) {
  glue::glue("SHOW COLUMNS FROM {table} LIKE 'nov';") |>
    db_get() |>
    nrow() >
    0
}


column_comment <- function(table, exclude_columns = "pk") {
  x = db_get(
    query = paste0(
      "SELECT COLUMN_NAME `Column`, COLUMN_COMMENT description FROM 
          information_schema.COLUMNS
              WHERE TABLE_NAME = ",

      shQuote(table)
    )
  )

  x[!x$Column %in% exclude_columns, ]
}
