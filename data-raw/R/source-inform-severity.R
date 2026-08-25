parse_inform_severity <- function(path, discovery) {
  required_sheet <- "INFORM Severity - country"
  sheets <- readxl::excel_sheets(path)
  if (!required_sheet %in% sheets) {
    stop("INFORM Severity workbook is missing the country worksheet.", call. = FALSE)
  }
  data <- suppressWarnings(readxl::read_excel(
    path,
    sheet = required_sheet,
    skip = 1L,
    col_types = "text"
  ))
  required <- c("COUNTRY", "ISO3", "INFORM Severity Index")
  if (!all(required %in% names(data))) {
    stop("INFORM Severity country worksheet has an unrecognised schema.", call. = FALSE)
  }
  data <- data[grepl("^[A-Z]{3}$", data$ISO3), , drop = FALSE]
  data$score <- suppressWarnings(as.numeric(data[["INFORM Severity Index"]]))
  if (anyDuplicated(data$ISO3)) {
    stop("INFORM Severity country worksheet contains duplicate ISO3 codes.", call. = FALSE)
  }

  about <- suppressWarnings(readxl::read_excel(
    path,
    sheet = "About",
    range = "A1:A4",
    col_names = FALSE,
    col_types = "text"
  ))[[1L]]
  date_value <- about[grepl("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$", about)]
  release_date <- if (length(date_value)) {
    as.Date(date_value[[1L]], format = "%d/%m/%Y")
  } else {
    as.Date(NA)
  }
  if (is.na(release_date)) {
    stop("Unable to parse the INFORM Severity release date.", call. = FALSE)
  }
  list(
    data = data.frame(
      source_country = data$COUNTRY,
      iso3 = data$ISO3,
      score = data$score,
      score_label = NA_character_,
      reference_year = format(release_date, "%Y-%m"),
      stringsAsFactors = FALSE
    ),
    source_version = format(release_date, "%Y-%m"),
    edition = format(release_date, "%B %Y"),
    reference_period = format(release_date, "%Y-%m"),
    publication_date = release_date,
    methodology_version = "2026-02"
  )
}

standardise_inform_severity <- function(
    parsed,
    discovery,
    geography,
    overrides) {
  build_current_grid(
    raw = parsed$data,
    geography = geography,
    index_id = "inform_severity",
    index_name = discovery$registry_entry$name[[1L]],
    source_version = parsed$source_version,
    edition = parsed$edition,
    reference_period = parsed$reference_period,
    publication_date = parsed$publication_date,
    retrieval_date = pipeline_retrieval_date(),
    score_direction = "higher_worse",
    rankable = TRUE,
    eligible_for_counts = discovery$registry_entry$eligible_for_counts[[1L]],
    methodology_version = parsed$methodology_version
  )
}

validate_inform_severity <- function(data, discovery) {
  scores <- data$score[!is.na(data$score)]
  messages <- character()
  status <- "PASS"
  if (length(scores) < discovery$registry_entry$expected_min_countries[[1L]] ||
      length(scores) > discovery$registry_entry$expected_max_countries[[1L]]) {
    status <- "FAIL"
    messages <- c(messages, "INFORM Severity country coverage is outside configured bounds.")
  }
  if (length(scores) &&
      (min(scores) < discovery$registry_entry$score_min[[1L]] ||
       max(scores) > discovery$registry_entry$score_max[[1L]])) {
    status <- "FAIL"
    messages <- c(messages, "INFORM Severity contains a score outside 0-10.")
  }
  validation_result(status, messages)
}
