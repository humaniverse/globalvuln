# One-time migration of the v0.1 bundled snapshot into the repository-owned
# canonical history and expanded source manifest. This script is not part of
# scheduled updates; approved outputs are committed and subsequently maintained
# by `_targets.R`.

source(file.path("R", "common-schema.R"))
source(file.path("data-raw", "R", "common-schema.R"))
source(file.path("data-raw", "R", "registry.R"))

registry <- read_source_registry()
legacy_environment <- new.env(parent = emptyenv())
load(file.path("data", "humanitarian_index_sources.rda"), legacy_environment)
legacy_manifest <- legacy_environment$humanitarian_index_sources

versions <- setNames(legacy_manifest$edition, legacy_manifest$source_id)
versions[["inform_severity"]] <- "2026-06"
versions[["debt_distress"]] <- "2026-03-31"
publication_dates <- setNames(
  rep(as.Date(NA), nrow(legacy_manifest)),
  legacy_manifest$source_id
)
publication_dates[["inform_risk"]] <- as.Date("2026-03-31")
publication_dates[["inform_severity"]] <- as.Date("2026-06-30")
publication_dates[["debt_distress"]] <- as.Date("2026-03-31")

history <- do.call(rbind, lapply(.index_ids, function(index_id) {
  environment <- new.env(parent = emptyenv())
  load(file.path("data", paste0(index_id, ".rda")), environment)
  data <- get(index_id, environment, inherits = FALSE)
  data$source_version <- versions[[index_id]]
  data$reference_period <- data$reference_year
  data$publication_date <- publication_dates[[index_id]]
  data$retrieval_date <- legacy_manifest$retrieval_date[
    match(index_id, legacy_manifest$source_id)
  ]
  covered <- !is.na(data$source_country)
  data$coverage_status <- ifelse(covered, "covered", "not_covered")
  data$coverage_status[covered & is.na(data$score)] <- "covered_not_scored"
  data$methodology_version <- if (index_id == "inform_severity") {
    "2026-02"
  } else if (index_id == "debt_distress") {
    "LIC-DSF"
  } else {
    NA_character_
  }
  coerce_canonical_types(data)
}))
rownames(history) <- NULL

manifest <- do.call(rbind, lapply(.index_ids, function(index_id) {
  old <- legacy_manifest[legacy_manifest$source_id == index_id, , drop = FALSE]
  entry <- registry[registry$index_id == index_id, , drop = FALSE]
  data <- history[history$index_id == index_id, , drop = FALSE]
  frame <- data.frame(
    index_id = index_id,
    index_name = old$source_name,
    publisher = entry$publisher,
    source_version = versions[[index_id]],
    edition = old$edition,
    reference_period = old$reference_year,
    publication_date = publication_dates[[index_id]],
    retrieval_date = as.Date(old$retrieval_date),
    source_url = ifelse(
      is.na(old$download_url),
      old$source_url,
      old$download_url
    ),
    methodology_url = entry$methodology_url,
    source_file_name = basename(old$local_file),
    source_content_hash = old$sha256,
    http_etag = NA_character_,
    http_last_modified = NA_character_,
    adapter_version = ifelse(entry$implemented, entry$adapter_version, "legacy-bootstrap"),
    pipeline_commit_sha = NA_character_,
    license = entry$license,
    redistribution_allowed = entry$redistribution_allowed,
    status = "approved",
    notes = "Migrated from the v0.1 approved package snapshot.",
    n_source_rows = sum(!is.na(data$source_country)),
    n_numeric_scores = sum(!is.na(data$score)),
    n_ranked = sum(!is.na(data$rank)),
    coverage_ok = old$coverage_ok,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  frame[manifest_columns]
}))
rownames(manifest) <- NULL
attr(history, "source_manifest") <- manifest

dir.create(file.path("data-raw", "approved"), recursive = TRUE, showWarnings = FALSE)
saveRDS(
  history,
  file.path("data-raw", "approved", "humanitarian_indices.rds"),
  version = 3,
  compress = "xz"
)
utils::write.csv(
  manifest,
  file.path("data-raw", "approved", "source_manifest.csv"),
  row.names = FALSE,
  na = ""
)
dir.create(file.path("inst", "extdata"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(
  manifest,
  file.path("inst", "extdata", "source_manifest.csv"),
  row.names = FALSE,
  na = ""
)
