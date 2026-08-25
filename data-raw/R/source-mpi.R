parse_mpi <- function(path, discovery) {
  required_sheet <- "gMPI_Table1"
  if (!required_sheet %in% readxl::excel_sheets(path)) {
    stop("Global MPI workbook is missing the Table 1 worksheet.", call. = FALSE)
  }
  raw <- read_unheaded_excel(path, required_sheet, skip = 7L)
  if (ncol(raw) < 4L) {
    stop("Global MPI Table 1 has an unrecognised schema.", call. = FALSE)
  }
  score <- suppressWarnings(as.numeric(raw[[4L]]))
  aggregate_names <- normalise_country_key(c(
    "Developing countries", "Small island developing states", "Arab States",
    "East Asia and the Pacific", "Europe and Central Asia",
    "Latin America and the Caribbean", "South Asia", "Sub-Saharan Africa"
  ))
  is_aggregate <- normalise_country_key(raw[[1L]]) %in% aggregate_names
  keep <- !is.na(score) & !is.na(raw[[1L]]) & !is_aggregate
  data <- data.frame(
    source_country = as.character(raw[[1L]][keep]),
    iso3 = NA_character_,
    score = score[keep],
    score_label = NA_character_,
    reference_year = as.character(raw[[2L]][keep]),
    stringsAsFactors = FALSE
  )
  year <- source_year(discovery$url, discovery$registry_entry$homepage_url[[1L]])
  if (is.na(year)) stop("Unable to derive the Global MPI edition.", call. = FALSE)
  edition <- paste("Global MPI", year)
  new_parsed_source(
    data,
    source_version = edition,
    edition = edition,
    reference_period = "country-specific survey year",
    publication_date = discovery$publication_date,
    methodology_version = as.character(year)
  )
}

standardise_mpi <- function(parsed, discovery, geography, overrides) {
  standardise_numeric_adapter(parsed, discovery, geography, overrides, "mpi")
}

validate_mpi <- function(data, discovery) {
  validate_numeric_adapter(data, discovery, "Global MPI")
}
