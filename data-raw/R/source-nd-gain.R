parse_nd_gain <- function(path, discovery) {
  listing <- utils::unzip(path, list = TRUE)$Name
  entries <- listing[
    grepl("(^|/)gain/gain[.]csv$", listing, perl = TRUE) &
      !grepl("__MACOSX", listing, fixed = TRUE)
  ]
  if (length(entries) != 1L) {
    stop("Could not identify the ND-GAIN overall score file in the ZIP.", call. = FALSE)
  }
  connection <- unz(path, entries[[1L]], open = "r")
  on.exit(close(connection), add = TRUE)
  raw <- utils::read.csv(connection, stringsAsFactors = FALSE, check.names = FALSE)
  require_columns(raw, c("Name", "ISO3"), "ND-GAIN overall score data")
  year_columns <- grep("^[0-9]{4}$", names(raw), value = TRUE)
  if (!length(year_columns)) {
    stop("ND-GAIN overall score data contain no annual columns.", call. = FALSE)
  }
  reference_year <- max(as.integer(year_columns))
  score <- suppressWarnings(as.numeric(raw[[as.character(reference_year)]]))
  data <- data.frame(
    source_country = raw$Name,
    iso3 = raw$ISO3,
    score = score,
    score_label = NA_character_,
    reference_year = as.character(reference_year),
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  release_year <- source_year(discovery$url, default = reference_year + 2L)
  edition <- paste(release_year, "release")
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = as.character(reference_year),
    publication_date = discovery$publication_date,
    methodology_version = as.character(release_year)
  )
}

standardise_nd_gain <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "nd_gain",
    allowed_non_master = c("HKG", "TWN", "XKX")
  )
}

validate_nd_gain <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "ND-GAIN")
}
