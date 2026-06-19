(function(window) {
  window.DataEntry = window.DataEntry || {};

  function px(value, fallback) {
    var out = parseInt(value, 10);
    return Number.isFinite(out) && out > 0 ? out : fallback;
  }

  window.DataEntry.codeCellRenderer = function(
    instance,
    td,
    row,
    col,
    prop,
    value,
    cellProperties
  ) {
    var txt = value == null ? '' : String(value);
    var height = px(cellProperties.codeCellHeight, 150);
    var bodyHeight = Math.max(height - 28, 24);

    Handsontable.dom.empty(td);

    td.classList.add('dataentry-code-td');
    td.style.height = height + 'px';

    var wrap = document.createElement('div');
    wrap.className = 'dataentry-code-cell';
    wrap.style.setProperty('--de-code-cell-height', height + 'px');
    wrap.style.setProperty('--de-code-body-height', bodyHeight + 'px');

    var bar = document.createElement('div');
    bar.className = 'dataentry-code-cell-bar';

    var meta = document.createElement('span');
    meta.className = 'dataentry-code-cell-meta';
    meta.textContent = txt.length + ' chars';

    var copy = document.createElement('button');
    copy.type = 'button';
    copy.className = 'dataentry-code-cell-button';
    copy.textContent = 'Copy';

    var paste = document.createElement('button');
    paste.type = 'button';
    paste.className = 'dataentry-code-cell-button';
    paste.textContent = 'Paste';

    var pre = document.createElement('pre');
    pre.className = 'dataentry-code-cell-code';
    pre.textContent = txt;

    function stop(e) {
      e.preventDefault();
      e.stopPropagation();
    }

    copy.addEventListener('mousedown', stop);
    paste.addEventListener('mousedown', stop);

    copy.addEventListener('click', function(e) {
      stop(e);

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(txt).then(function() {
          copy.textContent = 'Copied';
          setTimeout(function() { copy.textContent = 'Copy'; }, 900);
        });

        return;
      }

      var ta = document.createElement('textarea');
      ta.value = txt;
      ta.style.position = 'fixed';
      ta.style.left = '-9999px';

      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);

      copy.textContent = 'Copied';
      setTimeout(function() { copy.textContent = 'Copy'; }, 900);
    });

    paste.addEventListener('click', function(e) {
      stop(e);

      if (!(navigator.clipboard && navigator.clipboard.readText)) {
        paste.textContent = 'Blocked';
        setTimeout(function() { paste.textContent = 'Paste'; }, 1200);
        return;
      }

      navigator.clipboard.readText().then(function(newText) {
        instance.setDataAtCell(row, col, newText, 'dataentry-code-cell-paste');

        paste.textContent = 'Pasted';
        setTimeout(function() { paste.textContent = 'Paste'; }, 900);
      }).catch(function() {
        paste.textContent = 'Blocked';
        setTimeout(function() { paste.textContent = 'Paste'; }, 1200);
      });
    });

    bar.appendChild(meta);
    bar.appendChild(copy);
    bar.appendChild(paste);

    wrap.appendChild(bar);
    wrap.appendChild(pre);

    td.appendChild(wrap);

    return td;
  };
})(window);