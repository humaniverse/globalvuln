standardise_source <- function(parsed, discovery, approved_history, overrides) {
  adapter <- discovery$registry_entry$adapter[[1L]]
  standardise <- get(paste0("standardise_", adapter), mode = "function")
  result <- standardise(
    parsed,
    discovery,
    master_geography_from_history(approved_history),
    overrides
  )
  coerce_canonical_types(result)
}

build_current_grid <- function(
    raw,
    geography,
    index_id,
    index_name,
    source_version,
    edition,
    reference_period,
    publication_date,
    retrieval_date,
    score_direction,
    rankable,
    eligible_for_counts,
    methodology_version = NA_character_) {
  position <- match(geography$iso3, raw$iso3)
  score <- raw$score[position]
  reference_year <- raw$reference_year[position]
  reference_year[is.na(reference_year)] <- reference_period
  ranking <- rank_vulnerability(score, score_direction, rankable)
  covered <- !is.na(position)
  coverage_status <- ifelse(covered, "covered", "not_covered")
  coverage_status[covered & is.na(score)] <- "covered_not_scored"
  data.frame(
    country = geography$country,
    iso3 = geography$iso3,
    region = geography$region,
    subregion = geography$subregion,
    index_id = index_id,
    index_name = index_name,
    source_country = raw$source_country[position],
    score = score,
    score_label = raw$score_label[position],
    reference_year = reference_year,
    edition = edition,
    score_direction = score_direction,
    rankable = rankable,
    eligible_for_counts = eligible_for_counts,
    n_scored = as.integer(ranking$n_scored),
    rank = ranking$rank,
    decile = ranking$decile,
    top_10 = if (eligible_for_counts) ranking$top_10 else rep(NA, nrow(geography)),
    top_20 = if (eligible_for_counts) ranking$top_20 else rep(NA, nrow(geography)),
    source_version = source_version,
    reference_period = reference_period,
    publication_date = as.Date(publication_date),
    retrieval_date = as.Date(retrieval_date),
    coverage_status = coverage_status,
    methodology_version = methodology_version,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

pipeline_retrieval_date <- function() {
  as.Date(Sys.getenv(
    "GLOBALVULN_RETRIEVAL_DATE",
    unset = as.character(Sys.Date())
  ))
}
