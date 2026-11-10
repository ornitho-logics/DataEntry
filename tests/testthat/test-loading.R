test_that("save feedback covers validation, network latency, and failure exits", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "Node.js is required to execute loading JavaScript")

  script <- tempfile(fileext = ".js")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    "const assert = require('node:assert/strict');",
    "global.window = global;",
    "let click; const listeners = {};",
    "const message = {textContent: ''};",
    "const status = {hidden: true, querySelector: () => message};",
    "let ignoreChecks = {checked: false};",
    "const handlers = {};",
    "global.document = {",
    "  getElementById: id => id === 'ignore_checks' ? ignoreChecks : status,",
    "  addEventListener: (name, fn) => { listeners[name] = fn; if(name === 'click') click = fn; }",
    "};",
    "const events = {on: function(names, fn) {",
    "  names.split(' ').forEach(name => { handlers[name.split('.')[0]] = fn; });",
    "  return this;",
    "}};",
    "global.$ = () => events;",
    readLines(system.file("JS", "loading.js", package = "DataEntry")),
    "DataEntryLoading.start();",
    "assert(status.hidden, 'startup must not display Save feedback');",
    "let disabled = false, stopped = false;",
    "const button = {disabled: false, classList: {contains: () => disabled}};",
    "const event = {target: {closest: () => button},",
    "  preventDefault() {}, stopImmediatePropagation() { stopped = true; }};",
    "click(event); assert(stopped, 'Save must wait for the table value');",
    "handlers['shiny:idle']();",
    "stopped = false; click(event); assert(stopped, 'idle alone does not mean grid is ready');",
    "handlers['shiny:value']({name: 'table'});",
    "stopped = false; click(event);",
    "assert(!status.hidden); assert(!stopped);",
    "assert.equal(message.textContent, 'Validating data...');",
    "listeners.keydown(event); assert(stopped, 'keyboard edits must be blocked during saving');",
    "click(event); assert(stopped, 'duplicate clicks must be blocked');",
    "handlers['shiny:idle']();",
    "assert(status.hidden, 'idle clears feedback even when validation rejects the save');",
    "stopped = false; listeners.keydown(event); assert(!stopped, 'keyboard input must resume');",
    "disabled = true; click(event); assert(status.hidden); disabled = false;",
    "ignoreChecks.checked = true; click(event);",
    "assert.equal(message.textContent, 'Saving without validation');",
    "handlers['shiny:idle'](); ignoreChecks.checked = false; click(event);",
    "assert.equal(message.textContent, 'Validating data...');",
    "handlers['shiny:idle'](); ignoreChecks = null; click(event);",
    "assert.equal(message.textContent, 'Validating data...');",
    "handlers['shiny:disconnected'](); assert(status.hidden);",
    "DataEntryLoading.start();",
    "handlers['shiny:error']({name: 'table'}); handlers['shiny:idle']();",
    "assert(status.hidden, 'table errors must not leave Save feedback');"
  ), script)

  result <- system2(node, script, stdout = TRUE, stderr = TRUE)
  expect_null(attr(result, "status"), info = paste(result, collapse = "\n"))
})

test_that("editors use a grid spinner without the waiter bundle", {
  for (ui in list(ui_append_rows(), ui_edit_table(), ui_edit_rcode())) {
    rendered <- htmltools::renderTags(ui)
    names <- vapply(rendered$dependencies, `[[`, character(1), "name")
    expect_true("shinycssloaders-binding" %in% names)
    expect_false("waiter" %in% names)
    expect_match(rendered$html, "Validating data...", fixed = TRUE)
    expect_match(rendered$html, 'id="dataentry-save-status" hidden', fixed = TRUE)
    expect_no_match(rendered$html, "shiny-spinner-hideui", fixed = TRUE)
  }
})
