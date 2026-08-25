parse_hdi <- function(path, discovery) {
  raw <- read_publisher_csv(path)
  require_columns(raw, c("country", "iso3"), "HDI time-series data")
  hdi_columns <- grep("^hdi_[0-9]{4}$", names(raw), value = TRUE)
  if (!length(hdi_columns)) {
    stop("HDI time-series data contain no annual HDI columns.", call. = FALSE)
  }
  reference_year <- max(as.integer(sub("^hdi_", "", hdi_columns)))
  score <- suppressWarnings(as.numeric(raw[[paste0("hdi_", reference_year)]]))
  data <- data.frame(
    source_country = raw$country,
    iso3 = raw$iso3,
    score = score,
    score_label = NA_character_,
    reference_year = as.character(reference_year),
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  release_year <- source_year(discovery$url, default = reference_year + 2L)
  edition <- paste("Human Development Report", release_year)
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = as.character(reference_year),
    publication_date = discovery$publication_date,
    methodology_version = as.character(release_year)
  )
}

standardise_hdi <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "hdi",
    allowed_non_master = c("HKG", "TWN", "XKX")
  )
}

validate_hdi <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "HDI")
}
