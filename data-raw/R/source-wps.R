parse_wps <- function(path, discovery) {
  required_sheet <- "TABLE 1"
  if (!required_sheet %in% readxl::excel_sheets(path)) {
    stop("WPS workbook is missing TABLE 1.", call. = FALSE)
  }
  raw <- read_unheaded_excel(path, required_sheet, skip = 6L)
  if (ncol(raw) < 5L) {
    stop("WPS TABLE 1 has an unrecognised schema.", call. = FALSE)
  }
  data <- data.frame(
    source_country = as.character(raw[[2L]]),
    iso3 = toupper(trimws(as.character(raw[[3L]]))),
    score = suppressWarnings(as.numeric(raw[[5L]])),
    score_label = NA_character_,
    reference_year = NA_character_,
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  year <- source_year(discovery$url, discovery$registry_entry$homepage_url[[1L]])
  if (is.na(year)) stop("Unable to derive the WPS Index edition.", call. = FALSE)
  next_year <- substr(as.character(year + 1L), 3L, 4L)
  edition <- paste0(year, "/", next_year)
  data$reference_year <- as.character(year)
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = as.character(year),
    publication_date = discovery$publication_date,
    methodology_version = edition
  )
}

standardise_wps <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "wps",
    allowed_non_master = c("HKG", "TWN", "XKX", "XKS", "PRI")
  )
}

validate_wps <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "WPS Index")
}
