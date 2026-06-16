assign(
    'cnf_path',
    system.file("database/DataTable.cnf", package = "DataEntry"),
    .GlobalEnv
)

context("Functions returning data.table-s")

test_that("DT is returned", {
    x = data.table::data.table(
        x = 1:40,
        y = 1:40,
        z = rep(letters, 40, TRUE),
        q = rep(letters, 40, TRUE)
    )
    x[1:10, z := 'NA']

    expect_s3_class(meltall(x), "data.table")

    cleaner(x)
})

context("UI elements and helpers")

test_that("js functions", {
    expect_s3_class(js_insertMySQLTimeStamp(), "html")
    expect_s3_class(jquery_change_by_id(1, 2), "html")
})

context("emptyFrame")

test_that("all arguments work on emptyFrame", {
    expect_s3_class(
        emptyFrame(
            table = "data_entry"
        ),
        "data.table"
    )

    expect_s3_class(
        emptyFrame(
            table = "data_entry",
            preFilled = list(datetime_ = as.character(Sys.Date()))
        ),
        "data.table"
    )

    expect_s3_class(
        emptyFrame(
            table = "data_entry",
            colorder = c("ID", "sex", "nest")
        ),
        "data.table"
    )
})
