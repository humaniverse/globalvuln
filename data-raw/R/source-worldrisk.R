parse_worldrisk <- function(path, discovery) {
  raw <- as.data.frame(
    suppressWarnings(readxl::read_excel(path, sheet = 1L)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (ncol(raw) < 3L) {
    stop("WorldRiskIndex workbook has an unrecognised schema.", call. = FALSE)
  }
  data <- data.frame(
    source_country = as.character(raw[[1L]]),
    iso3 = toupper(trimws(as.character(raw[[2L]]))),
    score = suppressWarnings(as.numeric(raw[[3L]])),
    score_label = NA_character_,
    reference_year = NA_character_,
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  year <- source_year(
    discovery$url,
    source_version_from_manifest(discovery)
  )
  if (is.na(year)) stop("Unable to derive the WorldRiskIndex edition.", call. = FALSE)
  data$reference_year <- as.character(year)
  new_parsed_source(
    data,
    source_version = as.character(year),
    edition = as.character(year),
    reference_period = as.character(year),
    publication_date = discovery$publication_date,
    methodology_version = if (year >= 2022L) "2022" else as.character(year)
  )
}

standardise_worldrisk <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "worldrisk"
  )
}

validate_worldrisk <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "WorldRiskIndex")
}
