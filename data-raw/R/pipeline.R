read_approved_history <- function(
    path = file.path("data-raw", "approved", "humanitarian_indices.rds")) {
  history <- readRDS(path)
  history <- coerce_canonical_types(history)
  key <- history[c("index_id", "source_version", "iso3")]
  if (anyDuplicated(key)) {
    stop("Approved canonical history contains duplicate keys.", call. = FALSE)
  }
  history
}

read_approved_manifest <- function(
    path = file.path("data-raw", "approved", "source_manifest.csv")) {
  manifest <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = "",
    check.names = FALSE
  )
  missing <- setdiff(manifest_columns, names(manifest))
  if (length(missing)) {
    stop(
      "Approved source manifest is missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  manifest$publication_date <- as.Date(manifest$publication_date)
  manifest$retrieval_date <- as.Date(manifest$retrieval_date)
  manifest
}

process_manual_source <- function(
    index_id,
    path,
    registry = read_source_registry(),
    approved_history = read_approved_history(),
    approved_manifest = read_approved_manifest(),
    overrides = read_country_overrides()) {
  entry <- registry_entry(registry, index_id)
  if (entry$automated[[1L]]) {
    stop("`", index_id, "` is automated; run it through targets.", call. = FALSE)
  }
  if (!entry$implemented[[1L]]) {
    stop("The manual adapter for `", index_id, "` is not implemented.", call. = FALSE)
  }
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  discovery <- discover_source(entry, approved_manifest)
  discovery <- finalise_discovery(discovery, path, approved_manifest)
  parsed <- parse_source_file(path, discovery, approved_manifest)
  candidate <- standardise_source(parsed, parsed$discovery, approved_history, overrides)
  validation <- validate_source_candidate(candidate, parsed$discovery)
  comparison <- compare_source_candidate(candidate, approved_history, approved_manifest)
  result <- build_source_result(candidate, parsed, validation, comparison)
  assert_pipeline_valid(list(result))
  result
}

parse_source_file <- function(source_file, discovery, approved_manifest) {
  adapter <- discovery$registry_entry$adapter[[1L]]
  parse <- get(paste0("parse_", adapter), mode = "function")
  parsed <- parse(source_file, discovery)
  discovery$source_version <- parsed$source_version
  discovery$publication_date <- parsed$publication_date
  discovery$etag <- attr(source_file, "etag") %||% discovery$etag
  discovery$last_modified <- attr(source_file, "last_modified") %||%
    discovery$last_modified

  same_version <- approved_manifest[
    approved_manifest$index_id == discovery$index_id &
      approved_manifest$source_version == parsed$source_version,
    ,
    drop = FALSE
  ]
  revised <- discovery$changed && nrow(same_version) &&
    !discovery$content_hash %in% same_version$source_content_hash
  if (revised) {
    parsed$source_version <- paste0(
      parsed$source_version,
      "+",
      substr(discovery$content_hash, 1L, 8L)
    )
    discovery$source_version <- parsed$source_version
    discovery$revision <- TRUE
  } else {
    discovery$revision <- FALSE
  }
  parsed$discovery <- discovery
  parsed
}

build_source_result <- function(candidate, parsed, validation, comparison) {
  validation <- combine_validation(validation, comparison$validation)
  list(
    discovery = parsed$discovery,
    data = candidate,
    validation = validation,
    comparison = comparison$metrics,
    changed = isTRUE(parsed$discovery$changed)
  )
}

assemble_pipeline <- function(source_results, approved_history, approved_manifest) {
  source_results <- unname(source_results)
  assert_pipeline_valid(source_results)
  changed <- source_results[vapply(
    source_results,
    function(result) isTRUE(result$changed),
    logical(1)
  )]
  history <- approved_history
  manifest <- approved_manifest
  if (length(changed)) {
    history <- do.call(rbind, c(
      list(approved_history),
      lapply(changed, `[[`, "data")
    ))
    rownames(history) <- NULL
    if (anyDuplicated(history[c("index_id", "source_version", "iso3")])) {
      stop("Candidate publication would create duplicate history keys.", call. = FALSE)
    }
    entries <- do.call(rbind, lapply(changed, build_manifest_entry))
    manifest <- rbind(approved_manifest, entries)
    rownames(manifest) <- NULL
  }
  attr(history, "source_manifest") <- manifest
  list(
    changed = length(changed) > 0L,
    changed_sources = changed,
    source_results = source_results,
    history = history,
    manifest = manifest
  )
}

build_manifest_entry <- function(result) {
  discovery <- result$discovery
  entry <- discovery$registry_entry
  data <- result$data
  covered <- !is.na(data$source_country)
  frame <- data.frame(
    index_id = discovery$index_id,
    index_name = entry$name[[1L]],
    publisher = entry$publisher[[1L]],
    source_version = unique(data$source_version)[[1L]],
    edition = unique(data$edition)[[1L]],
    reference_period = unique(data$reference_period)[[1L]],
    publication_date = as.Date(unique(data$publication_date)[[1L]]),
    retrieval_date = as.Date(unique(data$retrieval_date)[[1L]]),
    source_url = discovery$url,
    methodology_url = entry$methodology_url[[1L]],
    source_file_name = basename(discovery$source_file),
    source_content_hash = discovery$content_hash,
    http_etag = discovery$etag %||% NA_character_,
    http_last_modified = discovery$last_modified %||% NA_character_,
    adapter_version = entry$adapter_version[[1L]],
    pipeline_commit_sha = git_commit_sha(),
    license = entry$license[[1L]],
    redistribution_allowed = entry$redistribution_allowed[[1L]],
    status = "approved_candidate",
    notes = if (isTRUE(discovery$revision)) {
      "Stable publisher version revised; source version includes checksum suffix."
    } else {
      NA_character_
    },
    n_source_rows = sum(covered),
    n_numeric_scores = sum(!is.na(data$score)),
    n_ranked = sum(!is.na(data$rank)),
    coverage_ok = result$validation$status != "FAIL",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  frame[manifest_columns]
}

current_history_views <- function(history, manifest) {
  approved <- manifest[manifest$status %in% c(
    "approved", "approved_candidate", "available"
  ), , drop = FALSE]
  effective_date <- as.Date(approved$publication_date)
  missing_date <- is.na(effective_date)
  effective_date[missing_date] <- as.Date(approved$retrieval_date[missing_date])
  effective_date[is.na(effective_date)] <- as.Date("1900-01-01")
  approved <- approved[order(approved$index_id, effective_date), , drop = FALSE]
  current <- approved[!duplicated(approved$index_id, fromLast = TRUE), ]
  versions <- setNames(current$source_version, current$index_id)
  keep <- history$index_id %in% names(versions) &
    history$source_version == unname(versions[history$index_id])
  history[keep, , drop = FALSE]
}
