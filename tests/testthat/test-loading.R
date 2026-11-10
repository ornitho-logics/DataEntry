test_that("loading feedback covers delayed grids, save latency, and failure exits", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "Node.js is required to execute loading JavaScript")

  script <- tempfile(fileext = ".js")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    "const assert = require('node:assert/strict');",
    "global.window = global;",
    "let grid = false, visible = false, shows = 0, hides = 0;",
    "let click, changed, disconnected = false;",
    "const message = {};",
    "const handlers = {};",
    "global.document = {body: {},",
    "  querySelector: () => grid,",
    "  getElementById: () => message,",
    "  addEventListener: (name, fn) => { click = fn; }",
    "};",
    "global.MutationObserver = class {",
    "  constructor(fn) { changed = fn; }",
    "  observe() {}",
    "  disconnect() { disconnected = true; }",
    "};",
    "global.waiter = {",
    "  show: (options) => { assert.equal(options.id, null); visible = true; shows++; },",
    "  hide: () => { visible = false; hides++; }",
    "};",
    "const events = {on: function(name, fn) { handlers[name.split('.')[0]] = fn; return this; }};",
    "global.$ = () => events;",
    readLines(system.file("JS", "loading.js", package = "DataEntry")),
    "DataEntryLoading.start({});",
    "assert(visible);",
    "handlers['shiny:idle']();",
    "assert(visible, 'idle before widget assets load must keep spinner');",
    "grid = true; changed();",
    "assert(!visible); assert(disconnected);",
    "let disabled = false, stopped = false;",
    "const button = {disabled: false, classList: {contains: () => disabled}};",
    "const event = {target: {closest: () => button},",
    "  preventDefault() {}, stopImmediatePropagation() { stopped = true; }};",
    "click(event);",
    "assert(visible); assert.equal(message.textContent, 'Saving...');",
    "const count = shows; click(event);",
    "assert(stopped); assert.equal(shows, count);",
    "handlers['shiny:busy'](); handlers['shiny:idle']();",
    "assert(!visible, 'idle clears spinner even when no grid update is sent');",
    "disabled = true; click(event); assert(!visible); disabled = false;",
    "click(event); handlers['shiny:disconnected'](); assert(!visible);",
    "grid = false; DataEntryLoading.start({});",
    "handlers['shiny:busy'](); handlers['shiny:error']({name: 'table'});",
    "handlers['shiny:idle'](); assert(!visible, 'table errors release loading overlay');"
  ), script)

  result <- system2(node, script, stdout = TRUE, stderr = TRUE)
  expect_null(attr(result, "status"), info = paste(result, collapse = "\n"))
})
