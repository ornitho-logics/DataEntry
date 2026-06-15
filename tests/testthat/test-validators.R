test_that("time_order_validator detects invalid time order", {
  x = data.table::data.table(
    cap_time = c("10:04", "16:40", "01:55"),
    bleeding_time = c("10:10", "16:30", "04:08"),
    rowid = 1:3
  )

  out = time_order_validator(
    x,
    time1 = "cap_time",
    time2 = "bleeding_time"
  )

  expect_equal(out$rowid, c(2, 3))
})
