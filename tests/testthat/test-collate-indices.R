summary_columns <- c(
  "indices_ranked_count", "top_10_count", "top_10_proportion",
  "top_20_count", "top_20_proportion"
)

test_that("wide output contains selected indices in the supplied order", {
  selected <- c("hdi", "inform_risk")
  result <- collate_indices(selected)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 195L)
  expect_false(anyDuplicated(result$iso3) > 0L)
  expect_identical(
    names(result),
    c(
      "country", "iso3", "region", "subregion",
      "hdi_score", "hdi_rank", "hdi_decile",
      "inform_risk_score", "inform_risk_rank", "inform_risk_decile",
      summary_columns
    )
  )
})

test_that("wide output includes only applicable special fields", {
  ordinary <- collate_indices("inform_risk")
  special <- collate_indices(c("ghi", "mpi", "debt_distress"))

  expect_false(any(c(
    "ghi_score_label", "mpi_reference_year",
    "debt_distress_class", "debt_distress_ordinal"
  ) %in% names(ordinary)))
  expect_true(all(c(
    "ghi_score_label", "mpi_reference_year",
    "debt_distress_class", "debt_distress_ordinal"
  ) %in% names(special)))
})

test_that("long output preserves the country and index order", {
  selected <- c("hdi", "inform_risk")
  result <- collate_indices(selected, format = "long")

  expect_equal(dim(result), c(390L, 24L))
  expect_identical(names(result)[20:24], summary_columns)
  expect_identical(result$index_id[1:2], selected)
  expect_false(anyDuplicated(result[c("iso3", "index_id")]) > 0L)
  expect_identical(unique(result$index_id), selected)

  first_country <- result[result$iso3 == result$iso3[[1L]], summary_columns]
  for (column in summary_columns) {
    expect_length(unique(first_country[[column]]), 1L)
  }
})

test_that("top thresholds use ranks rather than deciles", {
  long <- collate_indices("nd_gain", format = "long")
  afghanistan <- long[long$iso3 == "AFG", ]

  expect_equal(afghanistan$rank, 11L)
  expect_equal(afghanistan$decile, 1L)
  expect_false(afghanistan$top_10)
  expect_true(afghanistan$top_20)
  expect_equal(afghanistan$top_10_count, 0L)
  expect_equal(afghanistan$top_10_proportion, 0)
  expect_equal(afghanistan$top_20_count, 1L)
  expect_equal(afghanistan$top_20_proportion, 1)

  inform <- collate_indices("inform_risk", format = "long")
  expect_gt(sum(inform$top_10 %in% TRUE), 10L)
  expect_true(all(inform$rank[inform$top_10 %in% TRUE] <= 10L))
})

test_that("proportions use available selected eligible ranks", {
  result <- collate_indices(
    c("inform_risk", "nd_gain", "disaster_displacement"),
    format = "wide"
  )
  afghanistan <- result[result$iso3 == "AFG", ]

  expect_equal(afghanistan$indices_ranked_count, 2L)
  expect_equal(afghanistan$top_10_count, 1L)
  expect_equal(afghanistan$top_10_proportion, 0.5)
  expect_equal(afghanistan$top_20_count, 2L)
  expect_equal(afghanistan$top_20_proportion, 1)

  long <- collate_indices(
    c("inform_risk", "nd_gain", "disaster_displacement"),
    format = "long"
  )
  long_afghanistan <- long[long$iso3 == "AFG", ]
  for (column in summary_columns) {
    expect_identical(
      long_afghanistan[[column]],
      rep(afghanistan[[column]], 3L),
      info = column
    )
  }
})

test_that("zero available ranks produce zero counts and missing proportions", {
  result <- collate_indices(c("debt_distress", "disaster_displacement"))

  expect_true(all(result$indices_ranked_count == 0L))
  expect_true(all(result$top_10_count == 0L))
  expect_true(all(result$top_20_count == 0L))
  expect_true(all(is.na(result$top_10_proportion)))
  expect_true(all(is.na(result$top_20_proportion)))
})

test_that("index selection and format are validated", {
  expect_error(collate_indices(), "`indices` is required", fixed = TRUE)
  expect_error(collate_indices(list("hdi")), "character vector", fixed = TRUE)
  expect_error(collate_indices(character()), "at least one", fixed = TRUE)
  expect_error(collate_indices(NA_character_), "missing or empty", fixed = TRUE)
  expect_error(collate_indices(""), "missing or empty", fixed = TRUE)
  expect_error(
    collate_indices(c("hdi", "hdi")),
    "must be unique",
    fixed = TRUE
  )
  expect_error(collate_indices("unknown"), "Unknown index identifier")
  expect_error(collate_indices("hdi", format = "matrix"), "'arg' should be")
})
