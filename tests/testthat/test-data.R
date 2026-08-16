index_ids <- c(
  "inform_risk", "inform_severity", "underfunded_crisis",
  "oecd_fragility", "worldrisk", "nd_gain", "hdi", "mpi", "ghi", "ghs",
  "wps", "un_mvi", "debt_distress", "searo", "disaster_displacement",
  "internal_displacement"
)

test_that("the country dataset has one row per master country", {
  expect_s3_class(humanitarian_indices_country, "data.frame")
  expect_equal(dim(humanitarian_indices_country), c(195L, 59L))
  expect_false(anyNA(humanitarian_indices_country$iso3))
  expect_false(anyDuplicated(humanitarian_indices_country$iso3) > 0L)
  expect_setequal(
    names(humanitarian_indices_country)[1:4],
    c("country", "iso3", "region", "subregion")
  )
})

test_that("the long dataset is a complete country-index grid", {
  expect_equal(dim(humanitarian_indices_long), c(3120L, 19L))
  expect_identical(unique(humanitarian_indices_long$index_id), index_ids)
  expect_equal(sort(unique(humanitarian_indices_long$iso3)),
               sort(humanitarian_indices_country$iso3))
  expect_false(anyDuplicated(
    humanitarian_indices_long[c("iso3", "index_id")]
  ) > 0L)
})

test_that("individual datasets reproduce their long-table slices", {
  for (index_id in index_ids) {
    index_data <- get(index_id, envir = asNamespace("globalvuln"))
    expected <- humanitarian_indices_long[
      humanitarian_indices_long$index_id == index_id,
      ,
      drop = FALSE
    ]
    rownames(expected) <- NULL

    expect_equal(nrow(index_data), 195L, info = index_id)
    expect_identical(unique(index_data$index_id), index_id, info = index_id)
    expect_identical(index_data, expected, info = index_id)
  }
})

test_that("harmonised ranking fields obey their documented direction", {
  rankable <- humanitarian_indices_long$rankable &
    !is.na(humanitarian_indices_long$score)

  expect_true(all(!is.na(humanitarian_indices_long$rank[rankable])))
  expect_true(all(humanitarian_indices_long$rank[rankable] >= 1L))
  expect_true(all(humanitarian_indices_long$decile[rankable] %in% 1:10))
  expect_identical(
    humanitarian_indices_long$top_10[rankable],
    humanitarian_indices_long$decile[rankable] == 1L
  )
  expect_identical(
    humanitarian_indices_long$top_20[rankable],
    humanitarian_indices_long$decile[rankable] <= 2L
  )
})

test_that("special missingness and classification rules are preserved", {
  debt <- subset(humanitarian_indices_long, index_id == "debt_distress")
  displacement <- subset(
    humanitarian_indices_long,
    index_id == "disaster_displacement"
  )

  expect_true(all(is.na(debt$rank)))
  expect_true(all(is.na(debt$decile)))
  expect_true(all(is.na(displacement$score)))
  expect_true(all(is.na(displacement$rank)))
})

test_that("source provenance covers every index and the geography", {
  expect_setequal(
    humanitarian_index_sources$source_id,
    c(index_ids, "un_m49")
  )
  expect_s3_class(humanitarian_index_sources$retrieval_date, "Date")
  expect_true(all(humanitarian_index_sources$coverage_ok))
  expect_false(anyNA(humanitarian_index_sources$source_url))
})
