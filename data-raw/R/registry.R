read_source_registry <- function(path = file.path("data-raw", "sources.yml")) {
  raw <- yaml::read_yaml(path)
  if (!is.list(raw) || is.null(names(raw))) {
    stop("The source registry must be a named YAML mapping.", call. = FALSE)
  }
  rows <- lapply(names(raw), function(index_id) {
    entry <- raw[[index_id]]
    scalar <- function(name, default = NA) entry[[name]] %||% default
    data.frame(
      index_id = index_id,
      name = scalar("name", NA_character_),
      publisher = scalar("publisher", NA_character_),
      homepage_url = scalar("homepage_url", NA_character_),
      data_url = scalar("data_url", NA_character_),
      methodology_url = scalar("methodology_url", NA_character_),
      adapter = scalar("adapter", NA_character_),
      cadence = scalar("cadence", NA_character_),
      expected_publication_months = I(list(as.integer(
        scalar("expected_publication_months", integer())
      ))),
      automated = isTRUE(scalar("automated", FALSE)),
      implemented = isTRUE(scalar("implemented", FALSE)),
      discovery_method = scalar("discovery_method", NA_character_),
      vulnerability_direction = scalar(
        "vulnerability_direction",
        NA_character_
      ),
      score_min = as.numeric(scalar("score_min", NA_real_)),
      score_max = as.numeric(scalar("score_max", NA_real_)),
      expected_min_countries = as.integer(scalar(
        "expected_min_countries",
        NA_integer_
      )),
      expected_max_countries = as.integer(scalar(
        "expected_max_countries",
        NA_integer_
      )),
      eligible_for_counts = isTRUE(scalar("eligible_for_counts", TRUE)),
      expected_file_type = scalar("expected_file_type", NA_character_),
      license = scalar("license", NA_character_),
      redistribution_allowed = if (is.null(entry$redistribution_allowed)) {
        NA
      } else {
        isTRUE(entry$redistribution_allowed)
      },
      terms_url = scalar("terms_url", NA_character_),
      adapter_version = scalar("adapter_version", "pending"),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  registry <- do.call(rbind, rows)
  rownames(registry) <- NULL
  registry
}

validate_source_registry <- function(registry, supported_ids) {
  required <- c(
    "index_id", "name", "publisher", "homepage_url", "adapter", "cadence",
    "automated", "discovery_method", "vulnerability_direction",
    "eligible_for_counts", "license", "redistribution_allowed"
  )
  missing_columns <- setdiff(required, names(registry))
  if (length(missing_columns)) {
    stop(
      "Source registry is missing required fields: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  if (anyDuplicated(registry$index_id)) {
    stop("Source registry index IDs must be unique.", call. = FALSE)
  }
  if (!setequal(registry$index_id, supported_ids)) {
    stop("Source registry and supported package index IDs diverge.", call. = FALSE)
  }
  required_values <- c("index_id", "name", "publisher", "homepage_url", "adapter", "cadence")
  empty <- vapply(registry[required_values], function(value) {
    any(is.na(value) | !nzchar(value))
  }, logical(1))
  if (any(empty)) {
    stop(
      "Source registry has missing required values in: ",
      paste(names(empty)[empty], collapse = ", "),
      call. = FALSE
    )
  }
  allowed_cadences <- c(
    "monthly", "quarterly", "annual", "biennial", "triennial",
    "event_driven", "irregular"
  )
  invalid_cadence <- setdiff(unique(registry$cadence), allowed_cadences)
  if (length(invalid_cadence)) {
    stop("Unsupported source cadence: ", paste(invalid_cadence, collapse = ", "), call. = FALSE)
  }
  urls <- unlist(registry[c("homepage_url", "data_url", "methodology_url", "terms_url")])
  urls <- urls[!is.na(urls) & nzchar(urls)]
  if (any(!grepl("^https://", urls))) {
    stop("All configured source URLs must use HTTPS.", call. = FALSE)
  }
  contradictory <- !is.na(registry$score_min) & !is.na(registry$score_max) &
    registry$score_min > registry$score_max
  if (any(contradictory)) {
    stop("Source registry contains contradictory score bounds.", call. = FALSE)
  }
  automated <- registry$automated %in% TRUE
  implemented <- registry$implemented %in% TRUE
  if (any(automated & !registry$implemented)) {
    stop("Automated sources must have an implemented adapter.", call. = FALSE)
  }
  for (adapter in registry$adapter[implemented]) {
    functions <- paste0(
      c("discover_", "parse_", "standardise_", "validate_"),
      adapter
    )
    definition_environment <- environment(validate_source_registry)
    if (!all(vapply(
      functions,
      exists,
      logical(1),
      envir = definition_environment,
      mode = "function",
      inherits = TRUE
    ))) {
      stop("Missing adapter function(s) for `", adapter, "`.", call. = FALSE)
    }
  }
  registry
}

registry_entry <- function(registry, index_id) {
  row <- registry[registry$index_id == index_id, , drop = FALSE]
  if (nrow(row) != 1L) {
    stop("Expected one registry entry for `", index_id, "`.", call. = FALSE)
  }
  row
}

automated_registry_entries <- function(registry) {
  rows <- registry[registry$automated & registry$implemented, , drop = FALSE]
  split(rows, rows$index_id, drop = TRUE)
}
