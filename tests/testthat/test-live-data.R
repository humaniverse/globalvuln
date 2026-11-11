test_that("package data mode is offline and compatible with collate_indices", {
  indices <- c("hdi", "inform_risk")
  long <- globalvuln_data(source = "package", indices = indices)
  wide <- globalvuln_data(source = "package", indices = indices, format = "wide")
  expected <- collate_indices(indices)

  expect_equal(dim(long), c(390L, 24L))
  expect_identical(attr(long, "globalvuln_source"), "package")
  expect_identical(names(wide), names(expected))
  expect_equal(unclass(wide), unclass(expected), ignore_attr = TRUE)
  expect_s3_class(attr(long, "globalvuln_manifest"), "data.frame")
})

test_that("latest mode reads the approved board and never silently falls back", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  attr(history, "source_manifest") <- manifest
  board_path <- withr::local_tempdir()
  board <- pins::board_folder(board_path, versioned = TRUE)
  pins::pin_write(board, history, "humanitarian_indices", type = "rds")
  pins::pin_write(board, manifest, "humanitarian_index_sources", type = "rds")
  pins::write_board_manifest(board)
  withr::local_options(globalvuln.board_url = board_path)
  latest <- globalvuln_data(
    source = "latest",
    indices = "inform_severity"
  )

  expect_equal(nrow(latest), 195L)
  expect_identical(attr(latest, "globalvuln_source"), "latest")
  expect_true("source_version" %in% names(latest))

  empty_board <- withr::local_tempdir()
  withr::local_options(globalvuln.board_url = empty_board)
  expect_error(
    globalvuln_data(source = "latest", indices = "inform_severity"),
    "Use `source = \"package\"`"
  )
})

test_that("source status uses deterministic cadence rules", {
  manifest <- data.frame(
    index_id = rep("inform_severity", 2L),
    source_version = c("2026-06", "2026-07"),
    publication_date = as.Date(c("2026-06-30", "2026-07-31")),
    retrieval_date = as.Date(c("2026-08-04", "2026-08-25"))
  )
  local_mocked_bindings(
    load_approved_source_manifest = function() manifest,
    .package = "globalvuln"
  )
  status <- source_status(
    source = "package",
    as_of = as.Date("2026-09-25")
  )
  severity <- status[status$index_id == "inform_severity", ]

  expect_equal(nrow(status), 17L)
  expect_identical(severity$source_version, "2026-07")
  expect_identical(severity$publication_date, as.Date("2026-07-31"))
  expect_identical(severity$status, "expected_soon")
  expect_identical(
    evaluate_source_status(
      "monthly",
      as.Date("2026-06-30"),
      integer(),
      as.Date("2026-09-15")
    )$status,
    "update_overdue"
  )
})
