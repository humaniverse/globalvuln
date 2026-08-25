download_discovered_source <- function(
    discovery,
    download_dir = file.path("_targets", "downloads")) {
  dir.create(download_dir, recursive = TRUE, showWarnings = FALSE)
  extension <- discovery$registry_entry$expected_file_type[[1L]]
  destination <- file.path(
    download_dir,
    paste0(discovery$index_id, ".", extension)
  )
  request <- pipeline_request(discovery$url)
  homepage <- discovery$registry_entry$homepage_url[[1L]]
  if (!is.na(homepage) && nzchar(homepage)) {
    request <- httr2::req_headers(request, Referer = homepage)
  }
  response <- httr2::req_perform(request, path = destination)
  discovery_headers <- httr2::resp_headers(response)
  validate_download_signature(destination, extension)
  prepare_name <- paste0(
    "prepare_source_file_",
    discovery$registry_entry$adapter[[1L]]
  )
  if (exists(prepare_name, mode = "function", inherits = TRUE)) {
    destination <- get(prepare_name, mode = "function", inherits = TRUE)(
      destination,
      discovery
    )
    validate_download_signature(destination, extension)
  }
  destination <- normalizePath(destination, winslash = "/", mustWork = TRUE)
  attr(destination, "etag") <- discovery_headers[["etag"]] %||% NA_character_
  attr(destination, "last_modified") <- discovery_headers[["last-modified"]] %||% NA_character_
  destination
}

validate_download_signature <- function(path, expected_file_type) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    stop("Downloaded source file is empty.", call. = FALSE)
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, "raw", n = 512L)
  signature <- rawToChar(bytes[seq_len(min(4L, length(bytes)))])
  binary_signature <- startsWith(signature, "PK") || startsWith(signature, "%PDF")
  prefix <- if (binary_signature) "" else tolower(rawToChar(bytes))
  prefix <- sub("^\\xef\\xbb\\xbf", "", prefix)
  looks_like_html <- grepl("<(?:!doctype|html|head|body|script|table)", prefix, perl = TRUE)
  valid <- switch(
    expected_file_type,
    pdf = startsWith(signature, "%PDF"),
    xlsx = startsWith(signature, "PK"),
    csv = !looks_like_html,
    tsv = !looks_like_html,
    html = looks_like_html,
    zip = startsWith(signature, "PK"),
    FALSE
  )
  if (!isTRUE(valid)) {
    stop(
      "Downloaded content does not match expected type `",
      expected_file_type,
      "`; the publisher may have returned an error page.",
      call. = FALSE
    )
  }
  invisible(path)
}
