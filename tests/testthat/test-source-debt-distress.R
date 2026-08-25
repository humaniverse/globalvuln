test_that("IMF debt-distress text is parsed without inventing a rank", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  text <- paste(
    readLines(testthat::test_path("fixtures", "debt-distress.txt"), warn = FALSE),
    collapse = "\n"
  )
  parsed <- parse_debt_distress_text(text)

  expect_identical(parsed$source_version, "2026-03-31")
  expect_equal(nrow(parsed$data), 7L)
  expect_identical(
    parsed$data$score[parsed$data$source_country == "Afghanistan"],
    3
  )
  expect_identical(
    parsed$data$score_label[parsed$data$source_country == "Eritrea"],
    "No current DSA"
  )
})
