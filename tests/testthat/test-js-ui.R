test_that("dataentry_deps registers expected html dependencies", {
  deps <- htmltools::findDependencies(dataentry_deps())
  names <- vapply(deps, `[[`, character(1), "name")

  expect_setequal(
    names,
    c("dataentry-style", "popper", "tippy", "dataentry-code-cell-renderer")
  )
})

test_that("javascript helper functions return html fragments with expected content", {
  ts <- as.character(js_insertMySQLTimeStamp())
  unload <- as.character(js_before_unload())

  expect_match(ts, "keyup", fixed = TRUE)
  expect_match(ts, "toISOString", fixed = TRUE)
  expect_match(ts, "val.slice(0, -2)", fixed = TRUE)

  expect_match(unload, "DataEntryDirty", fixed = TRUE)
  expect_match(unload, "beforeunload", fixed = TRUE)
  expect_match(unload, "preventDefault", fixed = TRUE)
  expect_match(unload, "returnValue", fixed = TRUE)
})

test_that("js_hot_tippy_header returns JavaScript containing tooltip lookup data", {
  comments <- data.frame(
    Column = c("id", "measure"),
    description = c("Identifier", "Measurement")
  )

  out <- as.character(js_hot_tippy_header(comments, "description"))

  expect_match(out, "function(i, TH)", fixed = TRUE)
  expect_match(out, "titleLookup", fixed = TRUE)
  expect_match(out, "tippy", fixed = TRUE)
  expect_match(out, "Identifier", fixed = TRUE)
  expect_match(out, "Measurement", fixed = TRUE)
  expect_match(out, "allowHTML: true", fixed = TRUE)
})

test_that("ddmenu renders required controls with validation toggle", {
  html <- htmltools::renderTags(
    ddmenu(tnam = "data_entry")
  )$html

  expect_match(html, "data_entry", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_match(html, "ignore_checks", fixed = TRUE)
  expect_match(html, "cheatsheetButton", fixed = TRUE)
})

test_that("ddmenu can render without validation toggle", {
  html <- htmltools::renderTags(
    ddmenu(tnam = "inspectors", show_validation = FALSE)
  )$html

  expect_match(html, "inspectors", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_no_match(html, "ignore_checks", fixed = TRUE)
  expect_match(html, "cheatsheetButton", fixed = TRUE)
})

test_that("ui_edit_table renders the table output and menu", {
  html <- htmltools::renderTags(
    ui_edit_table(table_name = "data_entry")
  )$html

  expect_match(html, "table", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_match(html, "data_entry", fixed = TRUE)
})

test_that("ui_edit_rcode hides the validation toggle", {
  html <- htmltools::renderTags(
    ui_edit_rcode(table_name = "inspectors")
  )$html

  expect_match(html, "table", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_match(html, "inspectors", fixed = TRUE)
  expect_no_match(html, "ignore_checks", fixed = TRUE)
})

test_that("ui_append_rows renders the table output, issues panel placeholder, and ShinyJS support UI", {
  tags <- htmltools::renderTags(
    ui_append_rows(table_name = "data_entry")
  )

  html <- tags$html

  expect_match(html, 'id="table"', fixed = TRUE)
  expect_match(html, 'id="saveButton"', fixed = TRUE)
  expect_match(html, 'id="invalid_entries_panel"', fixed = TRUE)

  expect_no_match(html, 'id="run_save"', fixed = TRUE)

  expect_match(html, "toISOString", fixed = TRUE)
  expect_match(html, "beforeunload", fixed = TRUE)
  expect_match(html, "DataEntryDirty", fixed = TRUE)
})


test_that("js_hot_tippy_header tolerates missing tooltip rows", {
  comments <- data.frame(
    Column = "name",
    description = "Your full name."
  )

  out <- as.character(js_hot_tippy_header(comments, "description"))

  expect_match(out, "if (i < 0)", fixed = TRUE)
  expect_match(out, "this.getColHeader(i)", fixed = TRUE)
  expect_match(out, "return;", fixed = TRUE)
  expect_match(
    out,
    "var content = titleLookup[column];",
    fixed = TRUE
  )
  expect_match(out, "if (!content)", fixed = TRUE)
  expect_match(out, "tippy", fixed = TRUE)
})

test_that("header tooltips follow column names and ignore missing descriptions", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "Node.js is required to execute tooltip JavaScript")

  comments <- data.frame(
    Column = c("id", "measure", "empty", "missing", "quoted\"name"),
    description = c("Identifier", "Measurement", "", NA, "Quoted column")
  )
  callback <- as.character(js_hot_tippy_header(comments, "description"))
  script <- tempfile(fileext = ".js")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    paste0("var callback = ", callback, ";"),
    "var tooltips = [], destroyed = 0;",
    "function tippy(header, options) {",
    "  tooltips.push({column: header.column, content: options.content});",
    "}",
    "var columns = ['measure', 'unknown', 'id', 'empty', 'missing', 'constructor', 'quoted\"name'];",
    "var table = {getColHeader: function(i) { return columns[i]; }};",
    "columns.forEach(function(column, i) {",
    "  callback.call(table, i, {column: column, _tippy: {destroy: function() { destroyed++; }}});",
    "});",
    "callback.call(table, -1, {});",
    "console.log(JSON.stringify({tooltips: tooltips, destroyed: destroyed}));"
  ), script)

  out <- jsonlite::fromJSON(paste(system2(node, script, stdout = TRUE), collapse = "\n"))
  expect_equal(out$tooltips$column, c("measure", "id", "quoted\"name"))
  expect_equal(out$tooltips$content, c("Measurement", "Identifier", "Quoted column"))
  expect_equal(out$destroyed, 7L)
})
