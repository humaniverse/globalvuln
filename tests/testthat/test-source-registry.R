test_that("source registry is complete and internally valid", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  supported <- getFromNamespace(".index_ids", "globalvuln")

  expect_no_error(validate_source_registry(registry, supported))
  expect_setequal(registry$index_id, supported)
  expect_identical(
    registry$index_id[registry$automated],
    setdiff(getFromNamespace(".index_ids", "globalvuln"), "disaster_displacement")
  )
  expect_true(all(registry$implemented[registry$automated]))
  expect_true(all(registry$implemented))
})

test_that("installed cadence catalogue follows the authoritative registry", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  full <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  installed <- installed_source_registry()
  matched <- match(full$index_id, installed$index_id)

  expect_false(anyNA(matched))
  expect_identical(installed$name[matched], full$name)
  expect_identical(installed$cadence[matched], full$cadence)
  expect_identical(
    installed$expected_publication_months[matched],
    full$expected_publication_months
  )
})
