canonical_columns <- c(
  "country", "iso3", "region", "subregion", "index_id", "index_name",
  "source_country", "score", "score_label", "reference_year", "edition",
  "score_direction", "rankable", "eligible_for_counts", "n_scored", "rank",
  "decile", "top_10", "top_20", "source_version", "reference_period",
  "publication_date", "retrieval_date", "coverage_status",
  "methodology_version"
)

manifest_columns <- c(
  "index_id", "index_name", "publisher", "source_version", "edition",
  "reference_period", "publication_date", "retrieval_date", "source_url",
  "methodology_url", "source_file_name", "source_content_hash", "http_etag",
  "http_last_modified", "adapter_version", "pipeline_commit_sha", "license",
  "redistribution_allowed", "status", "notes", "n_source_rows",
  "n_numeric_scores", "n_ranked", "coverage_ok"
)

validation_result <- function(status = "PASS", messages = character()) {
  status <- match.arg(status, c("PASS", "WARNING", "FAIL"))
  structure(
    list(status = status, messages = unique(messages)),
    class = "globalvuln_validation"
  )
}

combine_validation <- function(...) {
  checks <- list(...)
  levels <- c(PASS = 1L, WARNING = 2L, FAIL = 3L)
  worst <- names(which.max(vapply(
    checks,
    function(check) levels[[check$status]],
    integer(1)
  )))
  validation_result(
    status = worst,
    messages = unlist(lapply(checks, `[[`, "messages"), use.names = FALSE)
  )
}

empty_canonical_data <- function(n = 0L) {
  data.frame(
    country = rep(NA_character_, n),
    iso3 = rep(NA_character_, n),
    region = rep(NA_character_, n),
    subregion = rep(NA_character_, n),
    index_id = rep(NA_character_, n),
    index_name = rep(NA_character_, n),
    source_country = rep(NA_character_, n),
    score = rep(NA_real_, n),
    score_label = rep(NA_character_, n),
    reference_year = rep(NA_character_, n),
    edition = rep(NA_character_, n),
    score_direction = rep(NA_character_, n),
    rankable = rep(NA, n),
    eligible_for_counts = rep(NA, n),
    n_scored = rep(NA_integer_, n),
    rank = rep(NA_integer_, n),
    decile = rep(NA_integer_, n),
    top_10 = rep(NA, n),
    top_20 = rep(NA, n),
    source_version = rep(NA_character_, n),
    reference_period = rep(NA_character_, n),
    publication_date = rep(as.Date(NA), n),
    retrieval_date = rep(as.Date(NA), n),
    coverage_status = rep(NA_character_, n),
    methodology_version = rep(NA_character_, n),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

coerce_canonical_types <- function(data) {
  missing <- setdiff(canonical_columns, names(data))
  template <- empty_canonical_data(nrow(data))
  for (column in missing) {
    data[[column]] <- template[[column]]
  }
  data <- data[canonical_columns]
  data$score <- as.numeric(data$score)
  data$n_scored <- as.integer(data$n_scored)
  data$rank <- as.integer(data$rank)
  data$decile <- as.integer(data$decile)
  data$rankable <- as.logical(data$rankable)
  data$eligible_for_counts <- as.logical(data$eligible_for_counts)
  data$top_10 <- as.logical(data$top_10)
  data$top_20 <- as.logical(data$top_20)
  data$publication_date <- as.Date(data$publication_date)
  data$retrieval_date <- as.Date(data$retrieval_date)
  data
}

rank_vulnerability <- function(score, direction, rankable = TRUE) {
  n_scored <- sum(!is.na(score))
  if (!rankable || !n_scored) {
    return(list(
      n_scored = n_scored,
      rank = rep(NA_integer_, length(score)),
      decile = rep(NA_integer_, length(score)),
      top_10 = rep(NA, length(score)),
      top_20 = rep(NA, length(score))
    ))
  }
  ranked_value <- if (identical(direction, "higher_worse")) -score else score
  rank <- as.integer(rank(ranked_value, ties.method = "min", na.last = "keep"))
  decile <- as.integer(pmin(10L, floor(10 * (rank - 1L) / n_scored) + 1L))
  list(
    n_scored = n_scored,
    rank = rank,
    decile = decile,
    top_10 = ifelse(is.na(rank), NA, rank <= 10L),
    top_20 = ifelse(is.na(rank), NA, rank <= 20L)
  )
}

master_geography_from_history <- function(history) {
  geography <- history[c("country", "iso3", "region", "subregion")]
  geography <- geography[!duplicated(geography$iso3), , drop = FALSE]
  geography <- geography[!is.na(geography$iso3), , drop = FALSE]
  rownames(geography) <- NULL
  geography
}

git_commit_sha <- function() {
  sha <- Sys.getenv("GITHUB_SHA", unset = "")
  if (nzchar(sha)) {
    return(sha)
  }
  result <- suppressWarnings(system2(
    "git",
    c("rev-parse", "HEAD"),
    stdout = TRUE,
    stderr = FALSE
  ))
  if (!length(result)) NA_character_ else result[[1L]]
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
