parse_disaster_displacement <- function(path, discovery) {
  if (!file.exists(path) || file.info(path)$size == 0L) {
    stop("Manual IDMC GDRM country export is missing or empty.", call. = FALSE)
  }
  raw <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    colClasses = "character",
    check.names = FALSE,
    na.strings = ""
  )
  required <- c(
    "iso3", "country", "aad_current_multihazard", "scenario", "metric",
    "hazard_scope", "source_snapshot_date", "aggregation_level", "notes"
  )
  require_columns(raw, required, "Manual IDMC GDRM country export")
  if (!nrow(raw)) {
    stop("Manual IDMC GDRM country export contains no rows.", call. = FALSE)
  }
  if (any(tolower(trimws(raw$scenario)) != "current")) {
    stop("GDRM scenario must be Current for every row.", call. = FALSE)
  }
  if (any(toupper(trimws(raw$metric)) != "AAD")) {
    stop("GDRM metric must be AAD for every row.", call. = FALSE)
  }
  hazard <- normalise_country_key(raw$hazard_scope)
  if (any(!hazard %in% c("multi hazard", "multihazard", "all"))) {
    stop("GDRM hazard_scope must be Multi-hazard or All.", call. = FALSE)
  }
  if (any(normalise_country_key(raw$aggregation_level) != "country")) {
    stop("GDRM aggregation_level must be Country for every row.", call. = FALSE)
  }
  score <- suppressWarnings(as.numeric(raw$aad_current_multihazard))
  if (any(is.na(score) | score < 0)) {
    stop("GDRM AAD values must be non-negative numbers.", call. = FALSE)
  }
  iso3 <- toupper(trimws(raw$iso3))
  if (any(!grepl("^[A-Z]{3}$", iso3)) || anyDuplicated(iso3)) {
    stop("GDRM manual file contains invalid or duplicate ISO3 rows.", call. = FALSE)
  }
  snapshot <- unique(raw$source_snapshot_date)
  snapshot <- snapshot[!is.na(snapshot) & nzchar(snapshot)]
  if (length(snapshot) != 1L || is.na(as.Date(snapshot))) {
    stop("GDRM source_snapshot_date must be one ISO date.", call. = FALSE)
  }
  data <- data.frame(
    source_country = raw$country,
    iso3 = iso3,
    score = score,
    score_label = NA_character_,
    reference_year = snapshot[[1L]],
    stringsAsFactors = FALSE
  )
  new_parsed_source(
    data,
    source_version = "GDRM 2.0",
    edition = "GDRM 2.0",
    reference_period = "current climate",
    publication_date = as.Date(snapshot[[1L]]),
    methodology_version = "GDRM 2.0"
  )
}

standardise_disaster_displacement <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "disaster_displacement"
  )
}

validate_disaster_displacement <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "IDMC GDRM")
}
