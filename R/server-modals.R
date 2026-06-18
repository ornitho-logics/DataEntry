server_cheatsheet_modal <- function(input) {
  observeEvent(input$cheatsheetButton, {
    showModal(modalDialog(
      title = "Data entry shortcuts:",
      includeMarkdown(system.file("cheatsheet.md", package = "DataEntry")),
      easyClose = TRUE,
      footer = NULL,
      size = "l"
    ))
  })
}
