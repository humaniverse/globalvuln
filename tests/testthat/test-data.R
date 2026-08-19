index_ids <- c(
  "inform_risk", "inform_severity", "underfunded_crisis",
  "oecd_fragility", "worldrisk", "nd_gain", "hdi", "mpi", "ghi", "ghs",
  "wps", "un_mvi", "debt_distress", "searo", "disaster_displacement",
  "internal_displacement"
)

load_package_data <- function(name) {
  data_environment <- new.env(parent = emptyenv())
  utils::data(list = name, package = "globalvuln", envir = data_environment)
  get(name, envir = data_environment, inherits = FALSE)
}

test_that("individual datasets share the complete master geography", {
  master_iso3 <- NULL

  for (index_id in index_ids) {
    index_data <- load_package_data(index_id)

    expect_s3_class(index_data, "data.frame")
    expect_equal(dim(index_data), c(195L, 19L), info = index_id)
    expect_identical(unique(index_data$index_id), index_id, info = index_id)
    expect_false(anyNA(index_data$iso3), info = index_id)
    expect_false(anyDuplicated(index_data$iso3) > 0L, info = index_id)
    expect_setequal(
      names(index_data)[1:4],
      c("country", "iso3", "region", "subregion")
    )

    if (is.null(master_iso3)) {
      master_iso3 <- index_data$iso3
    } else {
      expect_identical(index_data$iso3, master_iso3, info = index_id)
    }
  }
})

test_that("rank flags use country ranks rather than deciles", {
  for (index_id in index_ids) {
    index_data <- load_package_data(index_id)
    included <- index_data$eligible_for_counts %in% TRUE &
      !is.na(index_data$rank)

    expect_identical(
      index_data$top_10[included],
      index_data$rank[included] <= 10L,
      info = index_id
    )
    expect_identical(
      index_data$top_20[included],
      index_data$rank[included] <= 20L,
      info = index_id
    )
    expect_true(all(is.na(index_data$top_10[!included])), info = index_id)
    expect_true(all(is.na(index_data$top_20[!included])), info = index_id)
  }

  nd_gain <- load_package_data("nd_gain")
  afghanistan <- nd_gain[nd_gain$iso3 == "AFG", ]
  expect_equal(afghanistan$rank, 11L)
  expect_equal(afghanistan$decile, 1L)
  expect_false(afghanistan$top_10)
  expect_true(afghanistan$top_20)
})

test_that("harmonised ranking fields obey their documented direction", {
  for (index_id in index_ids) {
    index_data <- load_package_data(index_id)
    rankable <- index_data$rankable & !is.na(index_data$score)

    expect_true(all(!is.na(index_data$rank[rankable])), info = index_id)
    expect_true(all(index_data$rank[rankable] >= 1L), info = index_id)
    expect_true(all(index_data$decile[rankable] %in% 1:10), info = index_id)
  }
})

test_that("special missingness and classification rules are preserved", {
  debt <- load_package_data("debt_distress")
  displacement <- load_package_data("disaster_displacement")

  expect_true(all(is.na(debt$rank)))
  expect_true(all(is.na(debt$decile)))
  expect_true(all(is.na(displacement$score)))
  expect_true(all(is.na(displacement$rank)))
})

test_that("source provenance covers every index and the geography", {
  sources <- load_package_data("humanitarian_index_sources")

  expect_setequal(sources$source_id, c(index_ids, "un_m49"))
  expect_s3_class(sources$retrieval_date, "Date")
  expect_true(all(sources$coverage_ok))
  expect_false(anyNA(sources$source_url))
})

test_that("obsolete collated datasets are not shipped", {
  available <- utils::data(package = "globalvuln")$results[, "Item"]

  expect_false("humanitarian_indices_country" %in% available)
  expect_false("humanitarian_indices_long" %in% available)
})
