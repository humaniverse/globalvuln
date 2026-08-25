compare_source_candidate <- function(candidate, approved_history, approved_manifest) {
  index_id <- unique(candidate$index_id)[[1L]]
  previous_manifest <- approved_manifest[
    approved_manifest$index_id == index_id,
    ,
    drop = FALSE
  ]
  if (!nrow(previous_manifest)) {
    return(list(
      metrics = list(
        previous_version = NA_character_,
        source_countries_before = 0L,
        source_countries_after = sum(!is.na(candidate$source_country)),
        missing_scores_before = NA_integer_,
        missing_scores_after = sum(is.na(candidate$score)),
        median_absolute_score_change = NA_real_,
        rank_correlation = NA_real_,
        entered_top_20 = character(),
        left_top_20 = character()
      ),
      validation = validation_result("PASS")
    ))
  }
  previous_version <- previous_manifest$source_version[[nrow(previous_manifest)]]
  previous <- approved_history[
    approved_history$index_id == index_id &
      approved_history$source_version == previous_version,
    ,
    drop = FALSE
  ]
  positions <- match(candidate$iso3, previous$iso3)
  previous <- previous[positions, , drop = FALSE]
  paired_scores <- !is.na(candidate$score) & !is.na(previous$score)
  paired_ranks <- !is.na(candidate$rank) & !is.na(previous$rank)
  before_top <- previous$iso3[previous$top_20 %in% TRUE]
  after_top <- candidate$iso3[candidate$top_20 %in% TRUE]
  before_coverage <- sum(!is.na(previous$source_country))
  after_coverage <- sum(!is.na(candidate$source_country))
  coverage_change <- after_coverage - before_coverage
  validation <- if (abs(coverage_change) > max(10L, ceiling(0.2 * before_coverage))) {
    validation_result(
      "WARNING",
      paste("Source country coverage changed by", coverage_change, "countries.")
    )
  } else {
    validation_result("PASS")
  }
  list(
    metrics = list(
      previous_version = previous_version,
      source_countries_before = before_coverage,
      source_countries_after = after_coverage,
      missing_scores_before = sum(is.na(previous$score)),
      missing_scores_after = sum(is.na(candidate$score)),
      median_absolute_score_change = if (any(paired_scores)) {
        stats::median(abs(candidate$score[paired_scores] - previous$score[paired_scores]))
      } else {
        NA_real_
      },
      rank_correlation = if (sum(paired_ranks) >= 3L) {
        suppressWarnings(stats::cor(
          candidate$rank[paired_ranks],
          previous$rank[paired_ranks],
          method = "spearman"
        ))
      } else {
        NA_real_
      },
      entered_top_20 = setdiff(after_top, before_top),
      left_top_20 = setdiff(before_top, after_top)
    ),
    validation = validation
  )
}
