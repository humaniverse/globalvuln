pipeline_request <- function(url) {
  httr2::request(url) |>
    httr2::req_user_agent(
      "globalvuln-data-pipeline/0.2 (+https://github.com/humaniverse/globalvuln)"
    ) |>
    httr2::req_timeout(60) |>
    httr2::req_retry(
      max_tries = 3,
      backoff = function(tries) min(2 ^ tries, 10)
    )
}

discover_source <- function(entry, approved_manifest) {
  index_id <- entry$index_id[[1L]]
  adapter <- entry$adapter[[1L]]
  discover <- get(paste0("discover_", adapter), mode = "function")
  result <- discover(entry, approved_manifest)
  required <- c("index_id", "source_version", "url")
  if (!all(required %in% names(result))) {
    stop("Discovery result for `", index_id, "` violates the adapter contract.", call. = FALSE)
  }
  result$registry_entry <- entry
  result
}

latest_approved_version <- function(index_id, approved_manifest) {
  current <- approved_manifest[
    approved_manifest$index_id == index_id,
    ,
    drop = FALSE
  ]
  if (!nrow(current)) NA_character_ else current$source_version[[nrow(current)]]
}

new_discovery <- function(
    registry_entry,
    approved_manifest,
    url,
    publication_date = as.Date(NA),
    source_version = NULL) {
  index_id <- registry_entry$index_id[[1L]]
  if (is.null(source_version)) {
    source_version <- latest_approved_version(index_id, approved_manifest)
  }
  list(
    index_id = index_id,
    source_version = source_version,
    publication_date = as.Date(publication_date),
    url = url,
    etag = NA_character_,
    last_modified = NA_character_,
    changed = NA
  )
}

discover_fixed_source <- function(registry_entry, approved_manifest) {
  url <- registry_entry$data_url[[1L]]
  if (is.na(url) || !nzchar(url)) {
    stop(
      "No direct data URL is configured for `",
      registry_entry$index_id[[1L]],
      "`.",
      call. = FALSE
    )
  }
  new_discovery(registry_entry, approved_manifest, url)
}

absolute_source_url <- function(url, base_url) {
  if (grepl("^https://", url)) {
    return(url)
  }
  if (grepl("^//", url)) {
    return(paste0("https:", url))
  }
  origin <- sub("^(https://[^/]+).*$", "\\1", base_url)
  if (startsWith(url, "/")) {
    return(paste0(origin, url))
  }
  directory <- sub("[^/]*$", "", base_url)
  paste0(directory, url)
}

landing_file_candidates <- function(document, include, exclude = NULL) {
  links <- rvest::html_elements(document, "a, iframe")
  href <- rvest::html_attr(links, "href")
  src <- rvest::html_attr(links, "src")
  url <- ifelse(!is.na(href) & nzchar(href), href, src)
  label <- rvest::html_text2(links)
  searchable <- paste(utils::URLdecode(url), label)
  keep <- !is.na(url) & grepl(include, searchable, ignore.case = TRUE, perl = TRUE)
  if (!is.null(exclude)) {
    keep <- keep & !grepl(exclude, searchable, ignore.case = TRUE, perl = TRUE)
  }
  unique(url[keep])
}

discovery_sort_year <- function(url) {
  year <- source_year(utils::URLdecode(url))
  if (!is.na(year)) {
    return(year)
  }
  two_digit_source_year(utils::URLdecode(url), default = 0L)
}

discover_landing_file <- function(
    registry_entry,
    approved_manifest,
    include,
    exclude = NULL) {
  response <- httr2::req_perform(pipeline_request(
    registry_entry$homepage_url[[1L]]
  ))
  document <- httr2::resp_body_html(response)
  candidates <- landing_file_candidates(document, include, exclude)
  if (!length(candidates)) {
    fallback <- registry_entry$data_url[[1L]]
    if (!is.na(fallback) && nzchar(fallback)) {
      warning(
        "No landing-page source link matched for `",
        registry_entry$index_id[[1L]],
        "`; using the configured direct URL.",
        call. = FALSE
      )
      return(new_discovery(registry_entry, approved_manifest, fallback))
    }
    stop(
      "No landing-page source link matched for `",
      registry_entry$index_id[[1L]],
      "`.",
      call. = FALSE
    )
  }
  years <- vapply(candidates, discovery_sort_year, integer(1))
  candidate <- candidates[order(years, seq_along(candidates), decreasing = TRUE)][[1L]]
  url <- absolute_source_url(candidate, registry_entry$homepage_url[[1L]])
  new_discovery(registry_entry, approved_manifest, url)
}

discover_inform_risk <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "INFORM[_ -]?Risk[_ -]?20[0-9]{2}.*[.]xlsx"
  )
}

discover_inform_severity <- function(registry_entry, approved_manifest) {
  response <- httr2::req_perform(pipeline_request(
    registry_entry$homepage_url[[1L]]
  ))
  document <- httr2::resp_body_html(response)
  links <- rvest::html_elements(document, "a")
  href <- rvest::html_attr(links, "href")
  candidates <- href[
    !is.na(href) & grepl("Severity", href, ignore.case = TRUE) &
      grepl("[.]xlsx(?:[?].*)?$", href, ignore.case = TRUE)
  ]
  if (!length(candidates)) {
    stop("INFORM Severity landing page contains no XLSX release link.", call. = FALSE)
  }
  url <- candidates[[1L]]
  if (!grepl("^https://", url)) {
    origin <- sub("^(https://[^/]+).*$", "\\1", registry_entry$homepage_url[[1L]])
    url <- paste0(origin, if (startsWith(url, "/")) "" else "/", url)
  }
  decoded <- utils::URLdecode(url)
  version_match <- regexpr("20[0-9]{4}", decoded)
  if (version_match[[1L]] < 0L) {
    stop("Unable to derive the INFORM Severity release from its URL.", call. = FALSE)
  }
  release <- regmatches(decoded, version_match)
  source_version <- paste0(substr(release, 1L, 4L), "-", substr(release, 5L, 6L))
  list(
    index_id = "inform_severity",
    source_version = source_version,
    publication_date = as.Date(NA),
    url = url,
    etag = NA_character_,
    last_modified = NA_character_,
    changed = NA
  )
}

discover_debt_distress <- function(registry_entry, approved_manifest) {
  current <- approved_manifest[
    approved_manifest$index_id == "debt_distress",
    ,
    drop = FALSE
  ]
  list(
    index_id = "debt_distress",
    source_version = if (nrow(current)) current$source_version[[nrow(current)]] else NA_character_,
    publication_date = as.Date(NA),
    url = registry_entry$data_url[[1L]],
    etag = NA_character_,
    last_modified = NA_character_,
    changed = NA
  )
}

discover_underfunded_crisis <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "underfund(?:ing|ed).*table.*[.]html"
  )
}

discover_oecd_fragility <- discover_fixed_source

discover_worldrisk <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "WorldRiskIndex[-_ ]?20[0-9]{2}.*[.]xlsx",
    exclude = "meta|trend"
  )
}

discover_nd_gain <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "(?:nd.?gain|country.?index).*[.]zip"
  )
}

discover_hdi <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "composite[_ -]?indices.*time[_ -]?series.*[.]csv"
  )
}

discover_mpi <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "(?:gMPI|MPI).*Table(?:1and2|s? 1 and 2).*[.]xlsx"
  )
}

discover_ghi <- discover_fixed_source

discover_ghs <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "(?:GHS|Download the Data).*[.]csv"
  )
}

discover_wps <- function(registry_entry, approved_manifest) {
  discover_landing_file(
    registry_entry,
    approved_manifest,
    include = "WPS.*(?:Index)?.*Data.*[.]xlsx"
  )
}

discover_un_mvi <- discover_fixed_source

discover_searo <- discover_fixed_source

discover_disaster_displacement <- function(registry_entry, approved_manifest) {
  new_discovery(
    registry_entry,
    approved_manifest,
    registry_entry$homepage_url[[1L]],
    source_version = "GDRM 2.0"
  )
}

discover_internal_displacement <- discover_fixed_source

finalise_discovery <- function(discovery, source_file, approved_manifest) {
  discovery$content_hash <- digest::digest(
    file = source_file,
    algo = "sha256",
    serialize = FALSE
  )
  approved <- approved_manifest[
    approved_manifest$index_id == discovery$index_id,
    ,
    drop = FALSE
  ]
  if (!nrow(approved)) {
    discovery$changed <- TRUE
  } else {
    current <- approved[nrow(approved), , drop = FALSE]
    same_hash <- identical(
      discovery$content_hash,
      current$source_content_hash[[1L]]
    )
    same_version <- is.na(discovery$source_version) || identical(
      discovery$source_version,
      current$source_version[[1L]]
    )
    discovery$changed <- !(same_hash && same_version)
  }
  discovery$source_file <- source_file
  discovery
}
