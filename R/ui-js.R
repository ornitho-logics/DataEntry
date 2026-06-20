js_ctrl_s_open_ddmenu <- function(menu_id = "menu") {
  HTML(
    glue::glue(
      "
      <script>
        document.addEventListener('keydown', function(e) {{
          if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {{
            e.preventDefault();
            e.stopPropagation();

            var menu = document.getElementById('{menu_id}');
            if (!menu) {{
              return;
            }}

            if (menu.getAttribute('aria-expanded') !== 'true') {{
              menu.click();
            }}
          }}
        }}, true);
      </script>
      "
    )
  )
}


# translate two forward slashes to a Mysql timestamp (http://keycode.info/)
js_insertMySQLTimeStamp <- function() {
  HTML(
    "
    <script>
      $(function() {
         $(document).on('keyup', 'input, textarea', function(e) {
             var ts = new Date().toISOString().slice(0, 16).replace('T', ' ');
             var val = $(this).val();
             if ((e.key === '/' || e.which === 191) && val.slice(-2) === '//') {
                 $(this).val(val.slice(0, -2) + ts);
             }
         });
      });
    </script>
  "
  )
}

# prevent page exit
js_before_unload <- function() {
  HTML(
    "
    <script>
      window.DataEntryDirty = false;

      function markDataEntryDirty() {
        window.DataEntryDirty = true;
      }

      function markDataEntryClean() {
        window.DataEntryDirty = false;
      }

      document.addEventListener('input', markDataEntryDirty, true);
      document.addEventListener('change', markDataEntryDirty, true);
      document.addEventListener('paste', markDataEntryDirty, true);

      document.addEventListener('click', function(e) {
        if (e.target && e.target.id === 'saveButton') {
          markDataEntryClean();
        }
      }, true);

      window.addEventListener('beforeunload', function(e) {
        if (!window.DataEntryDirty) {
          return;
        }

        e.preventDefault();
        e.returnValue = '';
      });
    </script>
    "
  )
}

# add tooltips to a handsontable
# works on a data frame with two columns, one colum containing the fields of the table
# and one column containing the description of the fields.

js_hot_tippy_header <- function(x, tippy_column) {
  jj <- jsonlite::toJSON(x, auto_unbox = TRUE, na = "null")

  js_code <- glue::glue(
    "function(i, TH) {{
  var titleLookup = {jj};

  if (TH._tippy) {{
    TH._tippy.destroy();
  }}

  if (i < 0 || !titleLookup[i]) {{
    return;
  }}

  var content = titleLookup[i]['{tippy_column}'];

  if (!content) {{
    return;
  }}

  tippy(TH, {{
    content: content,
    allowHTML: true
  }});
}}"
  )

  htmlwidgets::JS(js_code)
}


js_hot_code_cell_renderer <- function() {
  htmlwidgets::JS("DataEntry.codeCellRenderer")
}
