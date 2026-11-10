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

    function blockInteraction(event) {
      if (!saving) return;
      event.preventDefault();
      event.stopImmediatePropagation();
    }

    // The overlay catches pointer input; capture keyboard edits too, since the
    // grid may still have focus when Save is activated.
    ['keydown', 'beforeinput', 'paste', 'cut'].forEach(function (name) {
      document.addEventListener(name, blockInteraction, true);
    });

    document.addEventListener('click', function (event) {
      if (saving) {
        blockInteraction(event);
        return;
      }
      var button = event.target.closest('#saveButton');
      if (!button) return;
      if (loading || button.disabled ||
          button.classList.contains('disabled') ||
          button.classList.contains('dataentry-button-disabled')) {
        event.preventDefault();
        event.stopImmediatePropagation();
        return;
      }
      var ignoreChecks = document.getElementById('ignore_checks');
      status.querySelector('.dataentry-save-message span').textContent =
        ignoreChecks && ignoreChecks.checked ?
          'Saving without validation' : 'Validating data...';
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
