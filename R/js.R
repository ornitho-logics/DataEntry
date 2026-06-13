#' @name js_insertMySQLTimeStamp
#' @title translate two forward slashes to a Mysql timestamp
#' @note used inside shiny apps. See http://keycode.info/
#' @export
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


#' @name js_before_unload
#' @title prevent page exit
#' @param msg   msg
#' @note used inside shiny apps
#' @export
js_before_unload <- function(msg = "Are you sure you want to exit the page?") {
  HTML(
    paste0(
      '
      <script>
       window.onbeforeunload = function() {
        return ',
      shQuote(msg),
      ';
      }
      </script>
        '
    )
  )
}


#' @name jquery_change_by_id
#' @title find and replace given `div` id.
#' @param divid   div id
#' @param newtext new text entry
#' @note used inside shiny apps
#' @export
jquery_change_by_id <- function(divid, newtext) {
  # $("#TABLE_NAME").css("color", "red");

  x <- (paste0(
    '<script>
  $(document).ready(function() {
  $("#',
    divid,
    '").text("',
    newtext,
    '");
  });
  </script>'
  ))

  HTML(x)
}


#' @name js_hot_tippy_header
#' @title add tooltips to a handsontable
#' @param x   A data frame with two columns, one colum containing the fields of the table
#'            and one column containing the description of the fields.
#' @param tippy_column   Character vector. the name of the column in x containing the description of the columns.
#' @note used within rhandsontable: e.g. rhandsontable(afterGetColHeader = js_hot_tippy_header(comments, "description"))
#' @seealso [DataEntry::column_comment()]
#' @export
js_hot_tippy_header <- function(x, tippy_column) {
  x <- cbind(loc = glue::glue("[,{1:nrow(x)}]"), x)
  jj <- jsonlite::toJSON(x, auto_unbox = TRUE)

  js_code <- glue::glue(
    "function(i, TH) {{
  var titleLookup = {jj};
  if (TH._tippy) {{
    TH._tippy.destroy();
  }}
  if (i >= 0) {{
    tippy(TH, {{
      content: titleLookup[i]['{tippy_column}'],
      allowHTML: true
    }});
  }}
}}"
  )

  htmlwidgets::JS(js_code)
}
