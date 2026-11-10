/* Keep feedback local to the browser so it also covers network latency. */
window.DataEntryLoading = {
  start: function (options) {
    options.id = null;
    var loading = true;
    var saving = false;
    var busy = false;
    var observer;

    function hideIfReady() {
      if (!loading && !saving && !busy) waiter.hide(null);
    }

    function gridReady() {
      if (!document.querySelector('#table .handsontable')) return;
      loading = false;
      if (observer) observer.disconnect();
      hideIfReady();
    }

    // Run before the menu is parsed, and wait for the actual widget DOM rather
    // than the first idle event (widget dependencies may still be downloading).
    waiter.show(options);
    observer = new MutationObserver(gridReady);
    observer.observe(document.body, {childList: true, subtree: true});
    gridReady();

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
      waiter.show(options);
      document.getElementById('dataentry-loading-message').textContent = 'Saving...';
    }, true);

    $(document).on('shiny:busy.dataentryLoading', function () {
      busy = true;
    }).on('shiny:idle.dataentryLoading', function () {
      busy = false;
      saving = false;
      gridReady();
      hideIfReady();
    }).on('shiny:error.dataentryLoading', function (event) {
      if (event.name === 'table') {
        loading = false;
        observer.disconnect();
        hideIfReady();
      }
    }).on('shiny:disconnected.dataentryLoading', function () {
      // Let Shiny display its connection/reconnect UI without an overlay.
      loading = false;
      saving = false;
      busy = false;
      observer.disconnect();
      waiter.hide(null);
    });
  }
};
