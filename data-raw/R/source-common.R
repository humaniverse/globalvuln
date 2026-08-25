new_parsed_source <- function(
    data,
    source_version,
    edition = source_version,
    reference_period = source_version,
    publication_date = as.Date(NA),
    methodology_version = NA_character_) {
  required <- c("source_country", "iso3", "score", "score_label", "reference_year")
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop(
      "Parsed source is missing required fields: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  data <- data[required]
  data$source_country <- as.character(data$source_country)
  data$iso3 <- toupper(trimws(as.character(data$iso3)))
  data$iso3[!nzchar(data$iso3)] <- NA_character_
  data$score <- suppressWarnings(as.numeric(data$score))
  data$score_label <- as.character(data$score_label)
  data$reference_year <- as.character(data$reference_year)
  rownames(data) <- NULL
  list(
    data = data,
    source_version = as.character(source_version),
    edition = as.character(edition),
    reference_period = as.character(reference_period),
    publication_date = as.Date(publication_date),
    methodology_version = as.character(methodology_version)
  )
}

read_unheaded_excel <- function(path, sheet, skip = 0L) {
  as.data.frame(
    suppressWarnings(readxl::read_excel(
      path,
      sheet = sheet,
      skip = skip,
      col_names = FALSE,
      .name_repair = "minimal"
    )),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

read_publisher_csv <- function(path) {
  data <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (length(names(data))) {
    first_name <- names(data)[[1L]]
    code_points <- utf8ToInt(first_name)
    if (length(code_points) && code_points[[1L]] == 65279L) {
      names(data)[[1L]] <- intToUtf8(code_points[-1L])
    }
  }
  data
}

source_year <- function(..., default = NA_integer_) {
  text <- paste(unlist(list(...), use.names = FALSE), collapse = " ")
  matches <- regmatches(text, gregexpr("20[0-9]{2}", text, perl = TRUE))[[1L]]
  years <- suppressWarnings(as.integer(matches))
  years <- years[!is.na(years) & years >= 2000L & years <= 2100L]
  if (!length(years)) as.integer(default) else max(years)
}

two_digit_source_year <- function(text, default = NA_integer_) {
  direct <- source_year(text)
  if (!is.na(direct)) {
    return(direct)
  }
  match <- regexec("(?:table|index|global)[^0-9]*([0-9]{2})(?:[^0-9]|$)", text, perl = TRUE, ignore.case = TRUE)
  captured <- regmatches(text, match)[[1L]]
  if (length(captured) == 2L) 2000L + as.integer(captured[[2L]]) else as.integer(default)
}

source_version_from_manifest <- function(discovery, fallback = NA_character_) {
  value <- discovery$source_version %||% NA_character_
  if (length(value) && !is.na(value) && nzchar(value)) value else fallback
}

score_direction_from_registry <- function(entry) {
  switch(
    entry$vulnerability_direction[[1L]],
    higher_is_worse = "higher_worse",
    lower_is_worse = "lower_worse",
    stop("Unsupported vulnerability direction.", call. = FALSE)
  )
}

standardise_numeric_adapter <- function(
    parsed,
    discovery,
    geography,
    overrides,
    index_id,
    rankable = TRUE,
    allowed_non_master = character()) {
  raw <- parsed$data
  missing_iso3 <- is.na(raw$iso3) | !grepl("^[A-Z]{3}$", raw$iso3)
  if (any(missing_iso3)) {
    raw$iso3[missing_iso3] <- harmonise_country_names(
      raw$source_country[missing_iso3],
      index_id,
      overrides
    )
  }
  unknown <- setdiff(unique(raw$iso3), geography$iso3)
  unexpected <- setdiff(unknown, allowed_non_master)
  if (length(unexpected)) {
    stop(
      "Unexpected non-master ISO3 code(s) for `", index_id, "`: ",
      paste(unexpected, collapse = ", "),
      call. = FALSE
    )
  }
  raw <- raw[raw$iso3 %in% geography$iso3, , drop = FALSE]
  if (anyDuplicated(raw$iso3)) {
    stop("Duplicate country rows for `", index_id, "`.", call. = FALSE)
  }
  build_current_grid(
    raw = raw,
    geography = geography,
    index_id = index_id,
    index_name = discovery$registry_entry$name[[1L]],
    source_version = parsed$source_version,
    edition = parsed$edition,
    reference_period = parsed$reference_period,
    publication_date = parsed$publication_date,
    retrieval_date = pipeline_retrieval_date(),
    score_direction = score_direction_from_registry(discovery$registry_entry),
    rankable = rankable,
    eligible_for_counts = discovery$registry_entry$eligible_for_counts[[1L]],
    methodology_version = parsed$methodology_version
  )
}

validate_numeric_adapter <- function(
    data,
    discovery,
    source_label,
    coverage = c("numeric", "covered")) {
  coverage <- match.arg(coverage)
  entry <- discovery$registry_entry
  scores <- data$score[!is.na(data$score)]
  n_covered <- if (coverage == "numeric") {
    length(scores)
  } else {
    sum(!is.na(data$source_country))
  }
  messages <- character()
  if (n_covered < entry$expected_min_countries[[1L]] ||
      n_covered > entry$expected_max_countries[[1L]]) {
    messages <- c(
      messages,
      paste(source_label, "country coverage is outside configured bounds.")
    )
  }
  minimum <- entry$score_min[[1L]]
  maximum <- entry$score_max[[1L]]
  if (length(scores) &&
      ((!is.na(minimum) && min(scores) < minimum) ||
       (!is.na(maximum) && max(scores) > maximum))) {
    messages <- c(
      messages,
      paste(source_label, "contains a score outside configured bounds.")
    )
  }
  validation_result(if (length(messages)) "FAIL" else "PASS", messages)
}

require_columns <- function(data, required, source_label) {
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop(
      source_label, " has an unrecognised schema; missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(data)
}
