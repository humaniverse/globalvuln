.index_ids <- c(
  "inform_risk", "inform_severity", "underfunded_crisis",
  "oecd_fragility", "worldrisk", "nd_gain", "hdi", "mpi", "ghi", "ghs",
  "wps", "un_mvi", "debt_distress", "searo", "disaster_displacement",
  "internal_displacement"
)

load_package_manifest <- function() {
  data_environment <- new.env(parent = emptyenv())
  utils::data(
    list = "humanitarian_index_sources",
    package = "globalvuln",
    envir = data_environment
  )
  get(
    "humanitarian_index_sources",
    envir = data_environment,
    inherits = FALSE
  )
}

load_approved_source_manifest <- function() {
  path <- system.file(
    "extdata",
    "source_manifest.csv",
    package = "globalvuln"
  )
  if (!nzchar(path)) {
    return(NULL)
  }
  manifest <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = "",
    check.names = FALSE
  )
  if ("publication_date" %in% names(manifest)) {
    manifest$publication_date <- as.Date(manifest$publication_date)
  }
  if ("retrieval_date" %in% names(manifest)) {
    manifest$retrieval_date <- as.Date(manifest$retrieval_date)
  }
  manifest
}

order_long_data <- function(long, indices) {
  country_order <- load_index_data(indices[[1L]])[[1L]]$iso3
  long <- long[
    order(match(long$iso3, country_order), match(long$index_id, indices)),
    ,
    drop = FALSE
  ]
  rownames(long) <- NULL
  long
}

add_rank_summaries <- function(long, indices) {
  long <- order_long_data(long, indices)
  included <- long$eligible_for_counts %in% TRUE & !is.na(long$rank)
  long$top_10 <- rep(NA, nrow(long))
  long$top_20 <- rep(NA, nrow(long))
  long$top_10[included] <- long$rank[included] <= 10L
  long$top_20[included] <- long$rank[included] <= 20L

  country_order <- unique(long$iso3)
  summaries <- summarise_country_ranks(long, country_order)
  summary_rows <- summaries[
    match(long$iso3, summaries$iso3),
    setdiff(names(summaries), "iso3"),
    drop = FALSE
  ]
  result <- cbind(long, summary_rows)
  rownames(result) <- NULL
  result
}

latest_history_rows <- function(history, manifest = NULL) {
  if (!"source_version" %in% names(history)) {
    return(history)
  }

  versions <- NULL
  if (!is.null(manifest) &&
      all(c("index_id", "source_version") %in% names(manifest))) {
    approved <- manifest
    if ("status" %in% names(approved)) {
      approved <- approved[
        approved$status %in% c("approved", "approved_candidate", "available"),
        ,
        drop = FALSE
      ]
    }
    if (nrow(approved)) {
      date_value <- rep(as.Date(NA), nrow(approved))
      if ("publication_date" %in% names(approved)) {
        date_value <- as.Date(approved$publication_date)
      }
      if ("retrieval_date" %in% names(approved)) {
        missing_date <- is.na(date_value)
        date_value[missing_date] <- as.Date(approved$retrieval_date[missing_date])
      }
      date_value[is.na(date_value)] <- as.Date("1900-01-01")
      approved <- approved[order(approved$index_id, date_value), , drop = FALSE]
      approved <- approved[!duplicated(approved$index_id, fromLast = TRUE), ]
      versions <- stats::setNames(approved$source_version, approved$index_id)
    }
  }

  if (is.null(versions)) {
    version_order <- unique(history[c("index_id", "source_version")])
    version_order <- version_order[order(
      version_order$index_id,
      version_order$source_version
    ), ]
    version_order <- version_order[
      !duplicated(version_order$index_id, fromLast = TRUE),
    ]
    versions <- stats::setNames(version_order$source_version, version_order$index_id)
  }

  keep <- history$index_id %in% names(versions) &
    history$source_version == unname(versions[history$index_id])
  history[keep, , drop = FALSE]
}
