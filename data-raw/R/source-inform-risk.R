parse_inform_risk <- function(path, discovery) {
  sheets <- readxl::excel_sheets(path)
  matches <- grep("^INFORM Risk 20[0-9]{2} \\(a-z\\)$", sheets, value = TRUE)
  if (length(matches) != 1L) {
    stop("INFORM Risk workbook has no unique country worksheet.", call. = FALSE)
  }
  raw <- read_unheaded_excel(path, matches[[1L]], skip = 2L)
  if (ncol(raw) < 3L) {
    stop("INFORM Risk country worksheet has an unrecognised schema.", call. = FALSE)
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
  if (anyDuplicated(data$iso3)) {
    stop("INFORM Risk country worksheet contains duplicate ISO3 codes.", call. = FALSE)
  }
  year <- source_year(matches[[1L]], discovery$url)
  data$reference_year <- as.character(year)
  decoded_url <- utils::URLdecode(discovery$url)
  version_match <- regexec("[_-]v([0-9]+)(?:[.]xlsx|$)", decoded_url, ignore.case = TRUE, perl = TRUE)
  captured <- regmatches(decoded_url, version_match)[[1L]]
  version <- if (length(captured) == 2L) {
    paste(strsplit(captured[[2L]], "", fixed = TRUE)[[1L]], collapse = ".")
  } else {
    NA_character_
  }
  edition <- if (!is.na(version)) paste(year, paste0("v", version)) else as.character(year)
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = as.character(year),
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_inform_risk <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "inform_risk"
  )
}

validate_inform_risk <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "INFORM Risk")
}
