parse_ghs <- function(path, discovery) {
  raw <- read_publisher_csv(path)
  require_columns(raw, c("Year", "Country", "OVERALL SCORE"), "GHS Index data")
  years <- suppressWarnings(as.integer(raw$Year))
  year <- max(years, na.rm = TRUE)
  if (!is.finite(year)) stop("GHS Index data contain no reference year.", call. = FALSE)
  raw <- raw[years == year, , drop = FALSE]
  data <- data.frame(
    source_country = raw$Country,
    iso3 = NA_character_,
    score = suppressWarnings(as.numeric(raw[["OVERALL SCORE"]])),
    score_label = NA_character_,
    reference_year = as.character(year),
    stringsAsFactors = FALSE
  )
  data <- data[!is.na(data$score), , drop = FALSE]
  new_parsed_source(
    data,
    source_version = as.character(year),
    edition = as.character(year),
    reference_period = as.character(year),
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_ghs <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "ghs",
    allowed_non_master = c("COK", "NIU", "TWN", "XKX")
  )
}

validate_ghs <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "GHS Index")
}
