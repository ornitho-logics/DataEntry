
CREATE DATABASE IF NOT EXISTS data_entry_tests;

CREATE USER IF NOT EXISTS 'data_entry_user'@'127.0.0.1' IDENTIFIED BY 'data_entry_pwd';
GRANT ALTER, CREATE, CREATE VIEW, DELETE, DROP, INDEX, INSERT, SELECT, SHOW VIEW, TRIGGER, UPDATE
ON data_entry_tests.* TO 'data_entry_user'@'127.0.0.1';


USE data_entry_tests;


DROP TABLE IF EXISTS data_entry; 
CREATE TABLE data_entry (
    author          VARCHAR(2)        NULL  DEFAULT NULL COMMENT 'author initials',
    datetime_       DATETIME          NULL  DEFAULT NULL COMMENT 'date and time',
    released_time   VARCHAR(5)        NULL  DEFAULT NULL COMMENT 'released time',
    nest            VARCHAR(5)        NULL  DEFAULT NULL COMMENT 'nest',
    recapture       INT(1)            NULL  DEFAULT NULL COMMENT 'recapture',
    sex             VARCHAR(1)        NULL  DEFAULT NULL COMMENT 'Observed sex.<br>Enter <code>M</code> for male or <code>F</code> for female.',
    measure         DOUBLE(20,10)     NULL  DEFAULT NULL COMMENT 'a measure',
    ID              INT(10)           NULL  DEFAULT NULL COMMENT 'an ID',
    comment         TEXT              NULL               COMMENT '<h1>hcomment field</h1>. This is somewhat a lengthy comment which is used to test the tooltip function on handsontable columns.  field. <hr> This is somewhat a lengthy comment which is used to test the tooltip function on handsontable columns.',
    nov             INT(1)            NULL  DEFAULT NULL COMMENT 'no validation',  
    pk              INT(10)           NOT NULL  AUTO_INCREMENT,
    PRIMARY KEY (pk)
    ) ; 


DROP TABLE IF EXISTS inspectors; 

CREATE TABLE IF NOT EXISTS inspectors (
  table_name varchar(128) NOT NULL
    COMMENT '<strong>Inspected table</strong><br>Name of the database table this inspector applies to. This value is used by <code>inspector_loader(table_name)</code> to find the validation logic for that table.',

  inspector longtext NOT NULL
    COMMENT '<strong>Validation rules</strong><br>Write the R checks that should run before this table is saved.<br><br>In these rules, <code>x</code> means the table being edited. Usually the rules are written as a <code>list(...)</code> of checks. For example:<br><code>list(x[, .(field)] |> is.na_validator())</code><br><br>If a check finds a problem, the app will show which rows need attention and will not save until the problems are fixed.',

  comments text NULL DEFAULT NULL
    COMMENT '<strong>Inspector notes</strong><br>Optional notes about this inspector',

  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    
);


INSERT INTO inspectors (table_name, inspector, comments)
VALUES ('data_entry', '
list(
  x[, .(author, datetime_, ID)] |>
    is.na_validator(),
  x[recapture == 0, .(sex, measure)] |>
    is.na_validator("Mandatory at first capture"),
  x[, .(datetime_)] |>
    POSIXct_validator(),

  x[, .(released_time)] |>
    hhmm_validator(),
  x[, .(sex)] |>
    is.element_validator(
      v = data.table(
        variable = "sex",
        set = list(c("M", "F"))
      )
    )
)
', 'any notes');


INSERT INTO inspectors (table_name, inspector, comments)
VALUES ('data_entry', '
list(
  x[, .(measure)] |>
    interval_validator(
      v = data.table(variable = "measure", lq = 10, uq = 20),
      "Meeasurement out of typical range"
    )
)
', 'any notes');



DROP TABLE IF EXISTS artifacts; 
CREATE TABLE IF NOT EXISTS artifacts (
  artifact_name varchar(128) NOT NULL
    COMMENT 'An identifier for the r-code',

  artifact longtext NULL
    COMMENT '<strong>Artifact content</strong><br>Saved artifact content. This can be any R code',

  comments text NULL
    COMMENT 'Optional notes about this artifact',

  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (artifact_name)
);
