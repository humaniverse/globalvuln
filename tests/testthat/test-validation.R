test_that("combined validation preserves the worst status and blocks publication", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  pass <- validation_result("PASS")
  warning <- validation_result("WARNING", "Coverage changed")
  fail <- validation_result("FAIL", "Invalid score")
  expect_identical(combine_validation(pass, warning)$status, "WARNING")
  expect_identical(combine_validation(warning, pass)$status, "WARNING")
  combined <- combine_validation(pass, warning, fail)
  expect_identical(combined$status, "FAIL")
  expect_setequal(combined$messages, c("Coverage changed", "Invalid score"))
  expect_identical(combine_validation(fail, pass, warning)$status, "FAIL")
  expect_identical(combine_validation(source = fail, common = pass)$status, "FAIL")
  expect_identical(combine_validation()$status, "PASS")
  result <- list(discovery = list(index_id = "clif_vi"), validation = combined)
  expect_error(assert_pipeline_valid(list(result)), "clif_vi: Coverage changed; Invalid score")
})

test_that("canonical validation rejects duplicate keys and missing scores", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discovery <- list(
    registry_entry = registry_entry(registry, "inform_severity")
  )
  current <- current_history_views(history, manifest)
  candidate <- current[current$index_id == "inform_severity", , drop = FALSE]

  expect_equal(nrow(candidate), 195L)
  expect_length(unique(candidate$source_version), 1L)
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
  current <- current_history_views(history, manifest)
  candidate <- current[current$index_id == "inform_severity", , drop = FALSE]
  covered <- which(!is.na(candidate$source_country))
  # Losing half the coverage is a large shift regardless of publisher coverage.
  n_removed <- ceiling(length(covered) / 2)
  expect_gt(n_removed, 10L)
  removed <- covered[seq_len(n_removed)]
  candidate$source_country[removed] <- NA_character_
  candidate$score[removed] <- NA_real_

  comparison <- compare_source_candidate(candidate, history, manifest)
  expect_identical(
    comparison$metrics$previous_version,
    unique(candidate$source_version)
  )
  expect_equal(comparison$metrics$source_countries_before, length(covered))
  expect_equal(
    comparison$metrics$source_countries_after,
    length(covered) - n_removed
  )
  expect_identical(comparison$validation$status, "WARNING")
})
