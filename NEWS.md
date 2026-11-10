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
