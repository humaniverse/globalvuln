prepare_source_file_ghi <- function(path, discovery) {
  document <- rvest::read_html(path)
  tables <- rvest::html_elements(document, "table")
  if (!length(tables)) {
    stop("Global Hunger Index page contains no ranking table.", call. = FALSE)
  }
  row_counts <- vapply(
    tables,
    function(table) length(rvest::html_elements(table, "tr")),
    integer(1)
  )
  table <- tables[[which.max(row_counts)]]
  if (max(row_counts) < 80L) {
    stop("Global Hunger Index ranking table has implausibly few rows.", call. = FALSE)
  }
  canonical <- paste0(
    '<!doctype html><html><head><meta charset="UTF-8"></head><body>',
    as.character(table),
    "</body></html>"
  )
  writeLines(canonical, path, useBytes = TRUE)
  path
}

parse_ghi <- function(path, discovery) {
  document <- rvest::read_html(path)
  rows <- rvest::html_elements(document, "table tr")
  parsed_rows <- lapply(rows, function(row) {
    cells <- rvest::html_elements(row, "td")
    if (length(cells) < 6L) {
      return(NULL)
    }
    country_links <- rvest::html_elements(cells[[2L]], "a")
    countries <- rvest::html_text2(country_links)
    if (!length(countries)) {
      countries <- rvest::html_text2(cells[[2L]])
    }
    countries <- trimws(countries[nzchar(trimws(countries))])
    if (!length(countries)) {
      return(NULL)
    }
    score_label <- rvest::html_text2(cells[[6L]])
    hidden <- rvest::html_text2(rvest::html_elements(cells[[6L]], "span.stealth"))
    if (length(hidden)) {
      for (value in hidden) {
        score_label <- sub(value, "", score_label, fixed = TRUE)
      }
    }
    score_label <- trimws(gsub("[[:space:]]+", " ", score_label))
    data.frame(
      source_country = countries,
      score_label = rep(score_label, length(countries)),
      stringsAsFactors = FALSE
    )
  })
  parsed_rows <- parsed_rows[!vapply(parsed_rows, is.null, logical(1))]
  if (!length(parsed_rows)) {
    stop("Global Hunger Index page contains no parseable country rows.", call. = FALSE)
  }
  data <- do.call(rbind, parsed_rows)
  exact <- grepl("^[0-9]+(?:[.][0-9]+)?$", data$score_label, perl = TRUE)
  data$iso3 <- NA_character_
  data$score <- ifelse(exact, suppressWarnings(as.numeric(data$score_label)), NA_real_)
  heading <- rvest::html_text2(rvest::html_element(document, "h1"))
  year <- source_year(
    heading,
    discovery$url,
    source_version_from_manifest(discovery)
  )
  if (is.na(year)) stop("Unable to derive the Global Hunger Index edition.", call. = FALSE)
  data$reference_year <- as.character(year)
  data <- data[c("source_country", "iso3", "score", "score_label", "reference_year")]
  new_parsed_source(
    data,
    source_version = as.character(year),
    edition = as.character(year),
    reference_period = as.character(year),
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_ghi <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(parsed, discovery, geography, overrides, "ghi")
}

validate_ghi <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "Global Hunger Index", "covered")
}
