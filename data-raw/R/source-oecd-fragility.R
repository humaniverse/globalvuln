parse_oecd_fragility <- function(path, discovery) {
  raw <- utils::read.delim(
    path,
    sep = "\t",
    dec = ",",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  require_columns(raw, c("country", "iso3", "overall"), "OECD fragility data")
  year <- source_year(
    discovery$registry_entry$methodology_url[[1L]],
    discovery$registry_entry$homepage_url[[1L]]
  )
  if (is.na(year)) {
    stop("Unable to derive the OECD fragility edition year.", call. = FALSE)
  }
  reference_period <- paste("predominantly", year - 2L)
  data <- data.frame(
    source_country = raw$country,
    iso3 = raw$iso3,
    score = suppressWarnings(as.numeric(raw$overall)),
    score_label = NA_character_,
    reference_year = reference_period,
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  edition <- paste("States of Fragility", year)
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = reference_period,
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_oecd_fragility <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "oecd_fragility"
  )
}

validate_oecd_fragility <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "OECD fragility")
}
