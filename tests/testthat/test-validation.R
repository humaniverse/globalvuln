test_that("canonical validation rejects duplicate keys and missing scores", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discovery <- list(
    registry_entry = registry_entry(registry, "inform_severity")
  )
  candidate <- history[history$index_id == "inform_severity", , drop = FALSE]

  expect_identical(validate_canonical_data(candidate, discovery)$status, "PASS")

  duplicated <- candidate
  duplicated$iso3[[2L]] <- duplicated$iso3[[1L]]
  expect_identical(validate_canonical_data(duplicated, discovery)$status, "FAIL")

  empty <- candidate
  empty$score <- NA_real_
  expect_identical(validate_canonical_data(empty, discovery)$status, "FAIL")
})

test_that("change analysis surfaces large coverage shifts as warnings", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  candidate <- history[history$index_id == "inform_severity", , drop = FALSE]
  covered <- which(!is.na(candidate$source_country))
  candidate$source_country[covered[1:20]] <- NA_character_
  candidate$score[covered[1:20]] <- NA_real_

  comparison <- compare_source_candidate(candidate, history, manifest)
  expect_identical(comparison$validation$status, "WARNING")
})
