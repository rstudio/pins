test_that("has useful print method", {
  expect_snapshot(board_folder("/tmp/test", name = "test"))
})

test_that("absent pins handled consistently", {
  board <- board_temp()
  pin_write(board, 1, "x")

  expect_equal(pin_list(board), "x")
  expect_equal(pin_exists(board, "x"), TRUE)
  expect_equal(pin_exists(board, "y"), FALSE)

  expect_error(pin_meta(board, "y"), class = "pins_pin_absent")
})

test_that("can remove a local pin", {
  board <- board_temp()

  pin_write(board, 1:10, "x")
  expect_equal(pin_list(board), "x")

  pin_delete(board, "x")
  expect_equal(pin_list(board), character())
})

test_that("can get versions", {
  b <- board_temp(versioned = TRUE)
  ui_loud()
  expect_snapshot(pin_write(b, 1:5, "x", type = "rds"))
  expect_equal(nrow(pin_versions(b, "x")), 1)
  first_version <- pin_versions(b, "x")$version

  expect_snapshot(pin_write(b, 1:6, "x", type = "rds"))
  expect_equal(nrow(pin_versions(b, "x")), 2)

  expect_equal(pin_read(b, "x"), 1:6)
  expect_equal(pin_read(b, "x", version = first_version), 1:5)
  expect_snapshot(pin_read(b, "x", version = "xxx"), error = TRUE)
})

test_that("can upload/download multiple files", {
  path1 <- withr::local_tempfile()
  writeLines("a", path1)
  path2 <- withr::local_tempfile()
  writeLines("b", path2)

  board <- board_temp()
  suppressMessages(pin_upload(board, c(path1, path2), "test"))

  out <- pin_download(board, "test")
  expect_equal(length(out), 2)
  expect_equal(readLines(out[[1]]), "a")
  expect_equal(readLines(out[[2]]), "b")
})

test_that("can't unversion an unversioned pin", {
  ui_loud()
  expect_snapshot(error = TRUE, {
    b <- board_temp(versioned = TRUE)
    pin_write(b, 1, "x", type = "rds")
    pin_write(b, 2, "x", type = "rds")
    pin_write(b, 3, "x", type = "rds", versioned = FALSE)
  })
})

test_that("can browse", {
  b <- board_folder("/tmp/test", name = "test")

  b %>% pin_write(1:10, "x")
  withr::defer(b %>% pin_delete("x"))

  expect_snapshot(b %>% pin_browse("x"))
  expect_snapshot(b %>% pin_browse("x", cache = TRUE), error = TRUE)
})

test_that("generates useful messages", {
  ui_loud()
  b <- board_temp()
  expect_snapshot(error = TRUE, {
    pin_read(b, "x")
    pin_write(b, 1:5, "x", type = "rds")
    pin_write(b, 1:5, "x", type = "rds")
    pin_write(b, 1:6, "x", type = "rds")
  })
})
