parse_un_mvi <- function(path, discovery) {
  pages <- pdftools::pdf_text(path)
  text <- paste(pages[seq_len(min(3L, length(pages)))], collapse = "\n")
  parse_un_mvi_text(text, discovery)
}

parse_un_mvi_text <- function(text, discovery) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE))
  pattern <- "^\\s*(.*?)\\s+([A-Z]{3})\\s+([0-9]+[.][0-9])\\s+([0-9]+[.][0-9])\\s+([0-9]+[.][0-9])\\s*$"
  matches <- regexec(pattern, lines, perl = TRUE)
  captured <- regmatches(lines, matches)
  captured <- captured[lengths(captured) == 6L]
  if (!length(captured)) {
    stop("UN MVI PDF contains no parseable country rows.", call. = FALSE)
  }
  rows <- do.call(rbind, lapply(captured, function(parts) parts[2:6]))
  data <- data.frame(
    source_country = trimws(rows[, 1L]),
    iso3 = rows[, 2L],
    score = as.numeric(rows[, 3L]),
    score_label = NA_character_,
    reference_year = "2023",
    stringsAsFactors = FALSE
  )
  new_parsed_source(
    data,
    source_version = "High-Level Panel results",
    edition = "High-Level Panel results",
    reference_period = "2023",
    publication_date = discovery$publication_date,
    methodology_version = "High-Level Panel 2023"
  )
}

standardise_un_mvi <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(parsed, discovery, geography, overrides, "un_mvi")
}

validate_un_mvi <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "UN MVI")
}
