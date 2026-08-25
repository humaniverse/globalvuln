parse_debt_distress <- function(path, discovery) {
  text <- paste(pdftools::pdf_text(path), collapse = "\n")
  parse_debt_distress_text(text)
}

parse_debt_distress_text <- function(text) {
  ascii <- iconv(text, from = "", to = "ASCII//TRANSLIT", sub = "")
  date_match <- regexec(
    "As of ([A-Za-z]+ [0-9]{1,2}, [0-9]{4})",
    ascii,
    perl = TRUE
  )
  captured_date <- regmatches(ascii, date_match)[[1L]]
  if (length(captured_date) != 2L) {
    stop("Unable to parse the IMF LIC DSA reference date.", call. = FALSE)
  }
  publication_date <- as.Date(captured_date[[2L]], format = "%B %d, %Y")
  if (is.na(publication_date)) {
    stop("Unable to parse the IMF LIC DSA reference date.", call. = FALSE)
  }

  lines <- strsplit(ascii, "\n", fixed = TRUE)[[1L]]
  row_pattern <- paste0(
    "^\\s*([0-9]{1,2})\\s+(.+?)\\s+",
    "([0-9]{1,2}/[0-9]{1,2}/[0-9]{4})\\s+",
    "(In debt distress|Moderate|High|Low)\\b"
  )
  matches <- regexec(row_pattern, lines, perl = TRUE)
  captured <- regmatches(lines, matches)
  captured <- captured[lengths(captured) == 5L]
  if (!length(captured)) {
    stop("The IMF LIC DSA PDF contains no parseable country rows.", call. = FALSE)
  }
  rows <- do.call(rbind, lapply(captured, function(parts) parts[2:5]))
  data <- data.frame(
    count = as.integer(rows[, 1L]),
    source_country = trimws(rows[, 2L]),
    latest_dsa_date = as.Date(rows[, 3L], format = "%m/%d/%Y"),
    latest_dsa_label = rows[, 3L],
    score_label = rows[, 4L],
    stringsAsFactors = FALSE
  )
  data$source_country <- sub("\\s+[456]/\\s*$", "", data$source_country)

  numbered_lines <- grep("^\\s*[0-9]{1,2}\\s+", lines, value = TRUE)
  if (!18L %in% data$count && any(grepl("^\\s*18\\s+Eritrea\\s*$", numbered_lines))) {
    data <- rbind(
      data,
      data.frame(
        count = 18L,
        source_country = "Eritrea",
        latest_dsa_date = as.Date(NA),
        latest_dsa_label = NA_character_,
        score_label = "No current DSA",
        stringsAsFactors = FALSE
      )
    )
  }
  data <- data[order(data$count), , drop = FALSE]
  if (anyDuplicated(data$count) || anyDuplicated(data$source_country)) {
    stop("The IMF LIC DSA PDF contains duplicate country rows.", call. = FALSE)
  }
  score_map <- c(
    "Low" = 1,
    "Moderate" = 2,
    "High" = 3,
    "In debt distress" = 4
  )
  data$score <- unname(score_map[data$score_label])
  list(
    data = data,
    source_version = format(publication_date, "%Y-%m-%d"),
    edition = format(publication_date, "%d %B %Y"),
    reference_period = paste("latest DSA as of", format(publication_date, "%Y-%m-%d")),
    publication_date = publication_date,
    methodology_version = "LIC-DSF"
  )
}

standardise_debt_distress <- function(
    parsed,
    discovery,
    geography,
    overrides) {
  raw <- parsed$data
  raw$iso3 <- harmonise_country_names(
    raw$source_country,
    "debt_distress",
    overrides
  )
  display_names <- c(
    "Cote d'Ivoire" = "C\u00f4te d'Ivoire",
    "Sao Tome and Principe" = "S\u00e3o Tom\u00e9 and Pr\u00edncipe"
  )
  display_match <- match(raw$source_country, names(display_names))
  raw$source_country[!is.na(display_match)] <- unname(
    display_names[display_match[!is.na(display_match)]]
  )
  raw$reference_year <- raw$latest_dsa_label
  raw <- raw[c("source_country", "iso3", "score", "score_label", "reference_year")]
  build_current_grid(
    raw = raw,
    geography = geography,
    index_id = "debt_distress",
    index_name = discovery$registry_entry$name[[1L]],
    source_version = parsed$source_version,
    edition = parsed$edition,
    reference_period = parsed$reference_period,
    publication_date = parsed$publication_date,
    retrieval_date = pipeline_retrieval_date(),
    score_direction = "higher_worse",
    rankable = FALSE,
    eligible_for_counts = FALSE,
    methodology_version = parsed$methodology_version
  )
}

validate_debt_distress <- function(data, discovery) {
  covered <- !is.na(data$source_country)
  labels <- unique(data$score_label[covered])
  expected_labels <- c("Low", "Moderate", "High", "In debt distress", "No current DSA")
  messages <- character()
  status <- "PASS"
  n_covered <- sum(covered)
  if (n_covered < discovery$registry_entry$expected_min_countries[[1L]] ||
      n_covered > discovery$registry_entry$expected_max_countries[[1L]]) {
    status <- "FAIL"
    messages <- c(messages, "IMF debt-distress country coverage is outside configured bounds.")
  }
  unexpected <- setdiff(labels, expected_labels)
  if (length(unexpected)) {
    status <- "FAIL"
    messages <- c(messages, paste("Unexpected IMF debt-distress class:", paste(unexpected, collapse = ", ")))
  }
  if (any(!is.na(data$rank)) || any(!is.na(data$decile))) {
    status <- "FAIL"
    messages <- c(messages, "Debt-distress classifications must not be ranked.")
  }
  validation_result(status, messages)
}
