test_that("common ranking preserves scores and harmonises direction", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  scores <- c(2, 8, 5, NA)
  higher <- rank_vulnerability(scores, "higher_worse")
  lower <- rank_vulnerability(scores, "lower_worse")

  expect_identical(higher$rank, c(3L, 1L, 2L, NA_integer_))
  expect_identical(lower$rank, c(1L, 3L, 2L, NA_integer_))
  expect_identical(scores, c(2, 8, 5, NA))
  expect_true(all(higher$decile[!is.na(higher$decile)] %in% 1:10))
})

test_that("country overrides are unique and resolve IMF names", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  overrides <- read_country_overrides(pipeline_path(
    "data-raw", "overrides", "countries.csv"
  ))
  observed <- harmonise_country_names(
    c("Gambia, The", "Lao P.D.R.", "Sao Tome and Principe"),
    "debt_distress",
    overrides
  )

  expect_identical(observed, c("GMB", "LAO", "STP"))
})
