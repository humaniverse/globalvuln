test_that("INFORM Severity fixture satisfies the adapter contract", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discovery <- list(
    registry_entry = registry_entry(registry, "inform_severity")
  )
  parsed <- parse_inform_severity(
    testthat::test_path("fixtures", "inform-severity.xlsx"),
    discovery
  )

  expect_identical(parsed$source_version, "2026-06")
  expect_identical(parsed$data$iso3, c("AFG", "BDI", "BEN"))
  expect_equal(parsed$data$score, c(9.2, 4.9, 4.6))
})
