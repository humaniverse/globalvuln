discover_clif_vi <- function(registry_entry, approved_manifest) {
  discover_fixed_source(registry_entry, approved_manifest)
}

# Read the publisher's JSON assignment as data, never as executable JavaScript.
read_clif_vi_countries <- function(path) {
  document <- rvest::read_html(path, encoding = "UTF-8")
  scripts <- rvest::html_elements(document, "script#charts-js-extra")
  if (length(scripts) != 1L) {
    stop("CliF-VI must contain exactly one charts-js-extra script.", call. = FALSE)
  }
  text <- rvest::html_text(scripts)
  if (!grepl("^\\s*var\\s+charts\\s*=", text, perl = TRUE)) {
    stop("CliF-VI charts script has an unrecognised assignment.", call. = FALSE)
  }
  payload <- sub("^\\s*var\\s+charts\\s*=\\s*", "", text, perl = TRUE)
  payload <- sub(";\\s*(?://[^\\r\\n]*\\s*)?$", "", payload, perl = TRUE)
  parsed <- tryCatch(
    jsonlite::fromJSON(payload, simplifyVector = FALSE),
    error = function(error) {
      stop("CliF-VI charts script contains malformed JSON.", call. = FALSE)
    }
  )
  if (!is.list(parsed) || !is.list(parsed$baseData)) {
    stop("CliF-VI is missing baseData.countryData.", call. = FALSE)
  }
  countries <- parsed$baseData$countryData
  if (!is.list(countries) || !length(countries) || !is.null(names(countries))) {
    stop("CliF-VI countryData must be a non-empty country array.", call. = FALSE)
  }
  score_field <- "2050_pessimistic_final_value"
  required <- c("country_name", "country_code", score_field)
  rows <- lapply(countries, function(country) {
    if (!is.list(country) || !all(required %in% names(country)) ||
        anyDuplicated(names(country))) {
      stop(
        "CliF-VI country record must contain country_name, country_code, and ",
        score_field, ".",
        call. = FALSE
      )
    }
    scalar_text <- function(value) {
      is.character(value) && length(value) == 1L &&
        !is.na(value) && nzchar(trimws(value))
    }
    if (!scalar_text(country$country_name) ||
        !scalar_text(country$country_code)) {
      stop("CliF-VI country name and ISO3 must be non-empty strings.", call. = FALSE)
    }
    iso3 <- toupper(trimws(country$country_code))
    if (!grepl("^[A-Z]{3}$", iso3)) {
      stop("CliF-VI contains an invalid ISO3 code: ", iso3, ".", call. = FALSE)
    }
    value <- country[[score_field]]
    if (is.null(value) || identical(value, "")) {
      score <- NA_real_
    } else {
      if (length(value) != 1L || !(is.character(value) || is.numeric(value))) {
        stop("CliF-VI selected score must be numeric or null.", call. = FALSE)
      }
      score <- suppressWarnings(as.numeric(value))
      if (!is.finite(score)) {
        stop("CliF-VI contains an invalid numeric score for ", iso3, ".", call. = FALSE)
      }
    }
    data.frame(
      country_name = country$country_name,
      country_code = iso3,
      `2050_pessimistic_final_value` = score,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  data <- do.call(rbind, rows)
  if (anyDuplicated(data$country_code)) {
    stop("CliF-VI contains duplicate country ISO3 codes.", call. = FALSE)
  }
  data <- data[order(data$country_code, method = "radix"), , drop = FALSE]
  rownames(data) <- NULL
  data
}

prepare_source_file_clif_vi <- function(path, discovery) {
  countries <- read_clif_vi_countries(path)
  payload <- jsonlite::toJSON(
    list(baseData = list(countryData = countries)),
    auto_unbox = TRUE, dataframe = "rows", digits = NA, na = "null"
  )
  # Escape HTML-significant characters while retaining valid, equivalent JSON.
  payload <- gsub("<", "\\u003c", payload, fixed = TRUE)
  prepared <- file.path(dirname(path), "clif_vi-prepared.html")
  html <- paste0(
    '<html><script id="charts-js-extra">var charts = ',
    payload, ";</script></html>\n"
  )
  # Binary UTF-8 with LF gives the same checksum on Windows and Linux.
  writeBin(charToRaw(enc2utf8(html)), prepared)
  prepared
}

parse_clif_vi <- function(path, discovery) {
  countries <- read_clif_vi_countries(path)
  period <- "2050 (pessimistic projection)"
  edition <- "2025 prototype (2050 pessimistic)"
  data <- data.frame(
    source_country = countries$country_name,
    iso3 = countries$country_code,
    score = countries[["2050_pessimistic_final_value"]],
    score_label = NA_character_,
    reference_year = period,
    stringsAsFactors = FALSE
  )
  new_parsed_source(
    data, source_version = edition, edition = edition,
    reference_period = period, publication_date = as.Date(NA),
    methodology_version = "June 2025"
  )
}

standardise_clif_vi <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(parsed, discovery, geography, overrides, "clif_vi")
}

validate_clif_vi <- function(data, discovery) {
  messages <- character()
  if (anyNA(data$edition) ||
      any(data$edition != "2025 prototype (2050 pessimistic)") ||
      anyNA(data$reference_period) ||
      any(data$reference_period != "2050 (pessimistic projection)") ||
      anyNA(data$methodology_version) ||
      any(data$methodology_version != "June 2025")) {
    messages <- c(messages, "CliF-VI edition, scenario, or methodology is incorrect.")
  }
  if (any(!is.finite(data$score[!is.na(data$score)]))) {
    messages <- c(messages, "CliF-VI contains a non-finite score.")
  }
  combine_validation(
    validate_numeric_adapter(data, discovery, "CliF-VI"),
    validate_numeric_adapter(data, discovery, "CliF-VI", coverage = "covered"),
    validation_result(if (length(messages)) "FAIL" else "PASS", messages)
  )
}
