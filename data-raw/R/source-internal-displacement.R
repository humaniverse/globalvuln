parse_internal_displacement <- function(path, discovery) {
  sheets <- readxl::excel_sheets(path)
  matches <- grep("^IDI 2022 values[[:space:]]*$", sheets, value = TRUE)
  if (length(matches) != 1L) {
    stop("Internal Displacement Index workbook has no unique values worksheet.", call. = FALSE)
  }
  raw <- read_unheaded_excel(path, matches[[1L]], skip = 3L)
  if (ncol(raw) < 46L) {
    stop("Internal Displacement Index worksheet has an unrecognised schema.", call. = FALSE)
  }
  data <- data.frame(
    source_country = as.character(raw[[3L]]),
    iso3 = toupper(trimws(as.character(raw[[1L]]))),
    score = suppressWarnings(as.numeric(raw[[46L]])),
    score_label = NA_character_,
    reference_year = "2022",
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  publication_year <- source_year(discovery$url, default = 2023L)
  edition <- paste("IDI", publication_year, "publication")
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = "2022",
    publication_date = discovery$publication_date,
    methodology_version = "IDI 2022"
  )
}

standardise_internal_displacement <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "internal_displacement"
  )
}

validate_internal_displacement <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "Internal Displacement Index")
}
