read_country_overrides <- function(
    path = file.path("data-raw", "overrides", "countries.csv")) {
  overrides <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = "")
  required <- c(
    "index_id", "source_country_name", "iso3", "reason", "introduced_date"
  )
  if (!all(required %in% names(overrides))) {
    stop("Country override file has an invalid schema.", call. = FALSE)
  }
  overrides$index_id <- trimws(overrides$index_id)
  overrides$source_country_name <- trimws(overrides$source_country_name)
  overrides$iso3 <- toupper(trimws(overrides$iso3))
  if (anyDuplicated(overrides[c("index_id", "source_country_name")])) {
    stop("Country override keys must be unique.", call. = FALSE)
  }
  if (any(!grepl("^[A-Z]{3}$", overrides$iso3))) {
    stop("Country overrides contain an invalid ISO3 code.", call. = FALSE)
  }
  overrides
}

normalise_country_key <- function(value) {
  value <- iconv(as.character(value), from = "", to = "ASCII//TRANSLIT", sub = "")
  value <- tolower(value)
  value <- gsub("[^a-z0-9]+", " ", value)
  trimws(gsub("[[:space:]]+", " ", value))
}

harmonise_country_names <- function(country, index_id, overrides) {
  country <- trimws(country)
  iso3 <- rep(NA_character_, length(country))
  source_overrides <- overrides[
    overrides$index_id %in% c("*", index_id),
    ,
    drop = FALSE
  ]
  source_overrides <- source_overrides[order(
    source_overrides$index_id != index_id
  ), , drop = FALSE]
  if (anyDuplicated(source_overrides$source_country_name)) {
    source_overrides <- source_overrides[
      !duplicated(source_overrides$source_country_name),
      ,
      drop = FALSE
    ]
  }
  matched <- match(country, source_overrides$source_country_name)
  iso3[!is.na(matched)] <- source_overrides$iso3[matched[!is.na(matched)]]
  unmatched <- is.na(iso3)
  if (any(unmatched)) {
    iso3[unmatched] <- suppressWarnings(countrycode::countrycode(
      country[unmatched],
      origin = "country.name",
      destination = "iso3c",
      warn = FALSE
    ))
  }
  unresolved <- unique(country[is.na(iso3) | !grepl("^[A-Z]{3}$", iso3)])
  if (length(unresolved)) {
    stop(
      "Unresolved country name(s) for `", index_id, "`: ",
      paste(unresolved, collapse = ", "),
      call. = FALSE
    )
  }
  iso3
}
