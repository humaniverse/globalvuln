#' Report cadence-aware source status
#'
#' Combines approved provenance with publication cadence metadata. An old but
#' still latest publisher edition is not automatically labelled stale.
#'
#' @param source Provenance source: the installed `"package"` snapshot or the
#'   approved `"latest"` board.
#' @param as_of Date on which status is evaluated. Exposed for reproducible
#'   reporting and tests.
#'
#' @return A data frame with one row per supported index.
#' @export
#' @seealso [globalvuln_data()], [humanitarian_index_sources]
#' @examples
#' source_status(source = "package", as_of = as.Date("2026-08-25"))
source_status <- function(
    source = c("package", "latest"),
    as_of = Sys.Date()) {
  source <- match.arg(source)
  as_of <- as.Date(as_of)
  if (length(as_of) != 1L || is.na(as_of)) {
    stop("`as_of` must be one non-missing date.", call. = FALSE)
  }

  registry <- installed_source_registry()
  if (identical(source, "package")) {
    manifest <- load_approved_source_manifest()
    if (is.null(manifest)) {
      manifest <- load_package_manifest()
      names(manifest)[names(manifest) == "source_id"] <- "index_id"
      names(manifest)[names(manifest) == "source_name"] <- "index_name"
      manifest$source_version <- manifest$edition
      manifest$publication_date <- as.Date(NA)
    }
  } else {
    live <- globalvuln_data(source = "latest", format = "long")
    manifest <- attr(live, "globalvuln_manifest", exact = TRUE)
  }

  manifest <- manifest[manifest$index_id %in% .index_ids, , drop = FALSE]
  if (anyDuplicated(manifest$index_id)) {
    manifest <- manifest[order(manifest$index_id, manifest$retrieval_date), ]
    manifest <- manifest[!duplicated(manifest$index_id, fromLast = TRUE), ]
  }
  matched <- match(registry$index_id, manifest$index_id)
  publication_date <- as.Date(manifest$publication_date[matched])
  retrieval_date <- as.Date(manifest$retrieval_date[matched])
  effective_date <- publication_date
  effective_date[is.na(effective_date)] <- retrieval_date[is.na(effective_date)]

  evaluated <- mapply(
    evaluate_source_status,
    cadence = registry$cadence,
    effective_date = effective_date,
    expected_months = registry$expected_publication_months,
    MoreArgs = list(as_of = as_of),
    SIMPLIFY = FALSE
  )

  data.frame(
    index_id = registry$index_id,
    index_name = registry$name,
    source_version = manifest$source_version[matched],
    publication_date = publication_date,
    retrieval_date = retrieval_date,
    cadence = registry$cadence,
    expected_publication_window = vapply(
      registry$expected_publication_months,
      function(months) {
        if (!length(months)) NA_character_ else paste(months, collapse = ",")
      },
      character(1)
    ),
    status = vapply(evaluated, `[[`, character(1), "status"),
    status_reason = vapply(evaluated, `[[`, character(1), "reason"),
    row.names = NULL,
    check.names = FALSE
  )
}

installed_source_registry <- function() {
  path <- system.file("extdata", "sources.yml", package = "globalvuln")
  if (!nzchar(path)) {
    stop("The installed source registry is unavailable.", call. = FALSE)
  }
  raw <- yaml::read_yaml(path)
  rows <- lapply(names(raw), function(index_id) {
    entry <- raw[[index_id]]
    data.frame(
      index_id = index_id,
      name = entry$name,
      cadence = entry$cadence,
      expected_publication_months = I(list(
        as.integer(entry$expected_publication_months %||% integer())
      )),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

evaluate_source_status <- function(cadence, effective_date, expected_months, as_of) {
  if (is.na(effective_date)) {
    return(list(status = "unknown_schedule", reason = "No approved source date is recorded."))
  }
  age <- as.integer(as_of - effective_date)
  if (cadence == "monthly") {
    if (age <= 45L) {
      return(list(status = "current", reason = "Approved data are within the monthly update window."))
    }
    if (age <= 62L) {
      return(list(status = "expected_soon", reason = "The next monthly release is expected soon."))
    }
    return(list(status = "update_overdue", reason = "No approved update has been recorded for more than two months."))
  }
  if (cadence == "quarterly") {
    if (age <= 120L) {
      return(list(status = "current", reason = "Approved data are within the quarterly update window."))
    }
    if (age <= 150L) {
      return(list(status = "expected_soon", reason = "The next quarterly release is expected soon."))
    }
    return(list(status = "update_overdue", reason = "The quarterly update window has passed."))
  }
  if (cadence %in% c("event_driven", "irregular")) {
    return(list(status = "irregular_schedule", reason = "The publisher has no fixed release schedule."))
  }
  if (cadence %in% c("biennial", "triennial")) {
    interval <- if (cadence == "biennial") 2 * 365L else 3 * 365L
    if (age > interval + 180L) {
      return(list(status = "update_overdue", reason = "The usual multi-year publication interval has passed."))
    }
    return(list(status = "latest_published", reason = "This is the latest approved multi-year edition."))
  }
  if (cadence == "annual") {
    month <- as.integer(format(as_of, "%m"))
    if (length(expected_months) && month %in% unique(c(expected_months, pmax(1L, expected_months - 1L)))) {
      return(list(status = "expected_soon", reason = "The source is in its expected annual publication window."))
    }
    if (age > 550L && length(expected_months) && month > max(expected_months)) {
      return(list(status = "update_overdue", reason = "The expected annual publication window has passed."))
    }
    return(list(status = "latest_published", reason = "This is the latest approved publisher edition."))
  }
  list(status = "unknown_schedule", reason = "No deterministic cadence rule is available.")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
