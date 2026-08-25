parse_searo <- function(path, discovery) {
  required_sheet <- "SEARO"
  if (!required_sheet %in% readxl::excel_sheets(path)) {
    stop("SEARO workbook is missing the SEARO worksheet.", call. = FALSE)
  }
  raw <- read_unheaded_excel(path, required_sheet, skip = 4L)
  if (ncol(raw) < 5L) {
    stop("SEARO worksheet has an unrecognised schema.", call. = FALSE)
  }
  data <- data.frame(
    source_country = as.character(raw[[1L]]),
    iso3 = toupper(trimws(as.character(raw[[3L]]))),
    score = suppressWarnings(as.numeric(raw[[5L]])),
    score_label = NA_character_,
    reference_year = NA_character_,
    stringsAsFactors = FALSE
  )
  data <- data[grepl("^[A-Z]{3}$", data$iso3) & !is.na(data$score), , drop = FALSE]
  decoded <- utils::URLdecode(discovery$url)
  year <- source_year(decoded)
  version_match <- regexec("v([0-9]+(?:[.][0-9]+)*)", decoded, ignore.case = TRUE, perl = TRUE)
  captured <- regmatches(decoded, version_match)[[1L]]
  version <- if (length(captured) == 2L) captured[[2L]] else NA_character_
  if (is.na(year)) stop("Unable to derive the SEARO edition.", call. = FALSE)
  edition <- paste(year, if (!is.na(version)) paste0("v", version) else "release")
  reference_year <- if (grepl("Dec[-_ ]?[0-9]{2}", decoded, ignore.case = TRUE)) {
    match <- regexec("Dec[-_ ]?([0-9]{2})", decoded, ignore.case = TRUE, perl = TRUE)
    paste("December", 2000L + as.integer(regmatches(decoded, match)[[1L]][[2L]]))
  } else {
    as.character(year - 1L)
  }
  data$reference_year <- reference_year
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = reference_year,
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_searo <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(parsed, discovery, geography, overrides, "searo")
}

validate_searo <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "SEARO")
}
