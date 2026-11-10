/* Keep feedback local to the browser so it also covers network latency. */
window.DataEntryLoading = {
  start: function () {
    var loading = true;
    var saving = false;
    var status = document.getElementById('dataentry-save-status');

    function finished() {
      saving = false;
      status.hidden = true;
    }

    document.addEventListener('click', function (event) {
      var button = event.target.closest('#saveButton');
      if (!button) return;
      if (loading || saving || button.disabled ||
          button.classList.contains('disabled') ||
          button.classList.contains('dataentry-button-disabled')) {
        event.preventDefault();
        event.stopImmediatePropagation();
        return;
      }
      saving = true;
      status.hidden = false;
    }, true);

    // Grid feedback belongs to the output, not the busy state of the whole app.
    $(document).on('shiny:value.dataentryLoading shiny:error.dataentryLoading', function (event) {
      if (event.name === 'table') {
        loading = false;
      }
    }).on('shiny:idle.dataentryLoading', finished)
      .on('shiny:disconnected.dataentryLoading', finished);
  }
};
