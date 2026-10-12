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

test_that("IMF country names from macOS transliteration retain canonical names", {
  skip_if_not(pipeline_available)
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  overrides <- read_country_overrides(pipeline_path("data-raw", "overrides", "countries.csv"))
  expect_identical(harmonise_country_names(
    "S~ao Tom'e and Pr'incipe", "debt_distress", overrides
  ), "STP")
  parsed <- parse_debt_distress_text(paste0(
    "As of March 31, 2026\n",
    "49   S~ao Tom'e and Pr'incipe   12/23/2025   In debt distress\n"
  ))
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discovery <- list(registry_entry = registry_entry(registry, "debt_distress"))
  candidate <- standardise_debt_distress(
    parsed, discovery, master_geography_from_history(history), overrides
  )
  expect_identical(candidate$source_country[candidate$iso3 == "STP"], "S\u00e3o Tom\u00e9 and Pr\u00edncipe")
  expect_equal(candidate$score[candidate$iso3 == "STP"], 4)
})
