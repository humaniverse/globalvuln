parse_underfunded_crisis <- function(path, discovery) {
  document <- rvest::read_html(path)
  scripts <- rvest::html_text2(rvest::html_elements(
    document,
    'script[type="application/json"]'
  ))
  selected <- scripts[grepl('"cum_percent_met"', scripts, fixed = TRUE)]
  if (length(selected) != 1L) {
    stop("Could not identify the Underfunded Crisis data payload.", call. = FALSE)
  }
  payload <- jsonlite::fromJSON(selected[[1L]], simplifyVector = TRUE)
  raw <- payload$x$tag$attribs$data
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  require_columns(raw, c("context", "cum_percent_met"), "Underfunded Crisis payload")
  raw <- raw[!grepl("^Regional:", raw$context), , drop = FALSE]
  score <- 100 * suppressWarnings(as.numeric(raw$cum_percent_met))
  data <- data.frame(
    source_country = as.character(raw$context),
    iso3 = NA_character_,
    score = score,
    score_label = ifelse(is.na(score), NA_character_, sprintf("%.1f%%", score)),
    reference_year = NA_character_,
    stringsAsFactors = FALSE
  )
  data <- data[!is.na(data$score), , drop = FALSE]
  year <- two_digit_source_year(discovery$url, source_year(discovery$url))
  if (is.na(year)) {
    stop("Unable to derive the Underfunded Crisis edition year.", call. = FALSE)
  }
  reference_period <- paste0(year - 4L, "-", year, " cumulative")
  data$reference_year <- reference_period
  new_parsed_source(
    data,
    source_version = as.character(year),
    edition = as.character(year),
    reference_period = reference_period,
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_underfunded_crisis <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(
    parsed, discovery, geography, overrides, "underfunded_crisis"
  )
}

validate_underfunded_crisis <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "Underfunded Crisis Index")
}
