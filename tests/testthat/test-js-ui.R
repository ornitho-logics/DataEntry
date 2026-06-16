# tests/testthat/test-js-ui.R

test_that("dataentry_deps registers expected html dependencies", {
  deps = htmltools::findDependencies(dataentry_deps())
  names = vapply(deps, `[[`, character(1), "name")

  expect_setequal(names, c("dataentry-style", "popper", "tippy"))
})

test_that("javascript helper functions return html fragments with expected content", {
  ts = as.character(js_insertMySQLTimeStamp())
  unload = as.character(js_before_unload("Leave?"))
  change = as.character(jquery_change_by_id("TABLE_NAME", "data_entry"))

  expect_match(ts, "keyup", fixed = TRUE)
  expect_match(ts, "toISOString", fixed = TRUE)
  expect_match(ts, "val.slice(0, -2)", fixed = TRUE)

  expect_match(unload, "window.onbeforeunload", fixed = TRUE)
  expect_match(unload, "Leave?", fixed = TRUE)

  expect_match(change, "#TABLE_NAME", fixed = TRUE)
  expect_match(change, "data_entry", fixed = TRUE)
})

test_that("js_hot_tippy_header returns JavaScript containing tooltip lookup data", {
  comments = data.frame(
    Column = c("id", "measure"),
    description = c("Identifier", "Measurement")
  )

  out = as.character(js_hot_tippy_header(comments, "description"))

  expect_match(out, "function(i, TH)", fixed = TRUE)
  expect_match(out, "titleLookup", fixed = TRUE)
  expect_match(out, "tippy", fixed = TRUE)
  expect_match(out, "Identifier", fixed = TRUE)
  expect_match(out, "Measurement", fixed = TRUE)
  expect_match(out, "allowHTML: true", fixed = TRUE)
})

test_that("ddmenu renders required controls with validation toggle when requested", {
  html = htmltools::renderTags(
    ddmenu(tnam = "data_entry", ignore_checks = TRUE)
  )$html

  expect_match(html, "data_entry", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_match(html, "ignore_checks", fixed = TRUE)
  expect_match(html, "helpButton", fixed = TRUE)
  expect_match(html, "cheatsheetButton", fixed = TRUE)
})

test_that("ddmenu omits validation toggle when ignore_checks is FALSE", {
  html = htmltools::renderTags(
    ddmenu(tnam = "data_entry", ignore_checks = FALSE)
  )$html

  expect_match(html, "saveButton", fixed = TRUE)
  expect_false(grepl("ignore_checks", html, fixed = TRUE))
})

test_that("dropDownNavPage_edit renders the table output and menu", {
  html = htmltools::renderTags(
    dropDownNavPage_edit(tableName = "data_entry")
  )$html

  expect_match(html, "table", fixed = TRUE)
  expect_match(html, "saveButton", fixed = TRUE)
  expect_match(html, "data_entry", fixed = TRUE)
})

test_that("dropDownNavPage renders the table output and ShinyJS support UI", {
  tags = htmltools::renderTags(
    dropDownNavPage(tableName = "data_entry")
  )

  html = tags$html

  expect_match(html, 'id="table"', fixed = TRUE)
  expect_match(html, 'id="saveButton"', fixed = TRUE)
  expect_match(html, 'id="ignore_checks"', fixed = TRUE)
  expect_match(html, 'id="run_save"', fixed = TRUE)
  expect_match(html, "toISOString", fixed = TRUE)
  expect_match(html, "window.onbeforeunload", fixed = TRUE)
})
