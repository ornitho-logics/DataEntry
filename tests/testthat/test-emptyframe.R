test_that("emptyFrame builds empty handsontable data with excluded columns and prefills", {
  local_mocked_bindings(
    db_get = function(query, ...) {
      data.table(
        pk = integer(),
        ID = character(),
        datetime_ = as.POSIXct(character()),
        measure = numeric()
      )
    },
    .package = "DataEntry"
  )

  out = emptyFrame(
    table = "data_entry",
    n = 3,
    excludeColumns = "pk",
    preFilled = list(ID = "bird-1"),
    colorder = c("ID", "datetime_", "measure")
  )

  expect_s3_class(out, "data.table")
  expect_equal(nrow(out), 3L)
  expect_named(out, c("ID", "datetime_", "measure"))
  expect_false("pk" %in% names(out))
  expect_equal(out$ID, rep("bird-1", 3))
  expect_type(out$datetime_, "character")
})
