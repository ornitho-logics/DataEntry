# DataEntry 1.2.1

* Replace the full-page `waiter` loader with a smaller `shinycssloaders` grid
  spinner, removing its JavaScript bundle and the wait for unrelated Shiny work
  at startup.
* Show "Validating data..." immediately on Save. Keep duplicate-click protection
  and clear the feedback on completion or disconnect.
* Keep the data visible during refreshes and show Save feedback with a larger
  spinner at the upper center of the page. Block mouse and keyboard interaction
  during validation and saving while keeping the data visible.
* Remove an unused Google Fonts stylesheet that could hold up page rendering
  on slow connections; retain the existing system font.

# DataEntry 1.2.0

* Show a full-page loading spinner until the grid is ready in all data-entry
  editors, including on slow connections.
* Show immediate feedback when Save is clicked and block repeated clicks while
  saving. Clear the spinner when processing finishes, including validation
  failures and save errors, or when the connection is lost.
* Add `waiter` to Imports.

# DataEntry 1.1.0

* Load validators from `inspector.R` in the app directory when present, taking
  precedence over inspector definitions stored in the database.
* Preserve the existing execution timeout and validation error handling for
  file-based inspectors. 
