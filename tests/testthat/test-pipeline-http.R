http_pipeline_inputs <- function(index_id = "ghs") {
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  list(
    entry = registry_entry(registry, index_id),
    manifest = manifest,
    history = history
  )
}

retained_http_result <- function(discovery, path, inputs) {
  observed <- finalise_discovery(discovery, path, inputs$manifest)
  parsed <- parse_source_file(path, observed, inputs$manifest)
  candidate <- standardise_source(parsed, observed, inputs$history, NULL)
  build_source_result(
    candidate, parsed,
    validate_source_candidate(candidate, observed),
    compare_source_candidate(candidate, inputs$history, inputs$manifest)
  )
}

mock_imf_error_redirect <- function(directory) {
  function(req) {
    body <- charToRaw("<!DOCTYPE html><html><body></body></html>")
    writeBin(body, file.path(directory, "debt_distress.pdf"))
    httr2::response(
      status_code = 200,
      url = paste0(
        "https://www.imf.org/redirect/?URL=$V&404;",
        "https://www.imf.org:443/external/pubs/ft/dsa/dsalist.pdf"
      ),
      headers = list("content-type" = "text/html; charset=utf-8"),
      body = body
    )
  }
}

test_that("publisher URLs encode spaces without double-encoding existing escapes", {
  skip_if_not(pipeline_available)
  url <- "https://example.org/202608 INFORM%20Severity.xlsx?name=a%26b&year=2026"
  expected <- "https://example.org/202608%20INFORM%20Severity.xlsx?name=a%26b&year=2026"
  expect_identical(pipeline_request(url)$url, expected)
  expect_identical(pipeline_request(expected)$url, expected)
})

test_that("a forbidden discovery retains approved data and reports unchecked freshness", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs()
  httr2::with_mocked_responses(list(httr2::response(status_code = 403)), {
    expect_warning(
      discovery <- discover_source(inputs$entry, inputs$manifest),
      "Source `ghs` discovery.*HTTP 403.*freshness was not checked"
    )
  })
  expect_true(discovery$unavailable)
  expect_false(discovery$changed)
  directory <- withr::local_tempdir()
  # Discovery already failed: do not issue another blocked request.
  httr2::with_mocked_responses(function(req) stop("Unexpected request"), {
    path <- download_discovered_source(
      discovery, directory, inputs$manifest
    )
  })
  expect_true(endsWith(path, ".unavailable.rds"))
  result <- retained_http_result(discovery, path, inputs)
  expected <- inputs$history[
    inputs$history$index_id == "ghs" &
      inputs$history$source_version == discovery$source_version,
    , drop = FALSE
  ]
  expect_identical(result$data, expected)
  expect_false(result$changed)
  expect_identical(result$validation$status, "WARNING")
  pipeline <- assemble_pipeline(list(result), inputs$history, inputs$manifest)
  expect_false(pipeline$changed)
  expect_identical(pipeline$manifest, inputs$manifest)
  expected_history <- inputs$history
  attr(expected_history, "source_manifest") <- inputs$manifest
  expect_identical(pipeline$history, expected_history)

  report <- file.path(directory, "summary.md")
  write_update_report(pipeline, report)
  text <- paste(readLines(report), collapse = "\n")
  expect_match(text, "Sources checked: 0")
  expect_match(text, "Validation: WARNING")
  expect_match(text, "approved editions retained")
  expect_match(text, "https://ghsindex.org/global/report/", fixed = TRUE)
})

test_that("a forbidden download never promotes a discovered release or error page", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs()
  discovery <- new_discovery(
    inputs$entry, inputs$manifest, inputs$entry$data_url[[1L]],
    source_version = "2099"
  )
  discovery$registry_entry <- inputs$entry
  httr2::with_mocked_responses(list(httr2::response(
    status_code = 403, body = charToRaw("<html>Cloudflare challenge</html>")
  )), {
    expect_warning(
      path <- download_discovered_source(
        discovery, withr::local_tempdir(), inputs$manifest
      ),
      "Source `ghs` download.*HTTP 403"
    )
  })
  result <- retained_http_result(discovery, path, inputs)
  expect_identical(result$discovery$source_version, "2021")
  expect_false(result$changed)
  expect_null(result$discovery$content_hash)
  expect_true(all(result$data$source_version == "2021"))
  expect_identical(result$validation$status, "WARNING")
})

test_that("HTTP 403 cannot hide a source with no approved data", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs()
  manifest <- inputs$manifest[inputs$manifest$index_id != "ghs", ]
  httr2::with_mocked_responses(list(httr2::response(status_code = 403)), {
    expect_error(
      discover_source(inputs$entry, manifest),
      "No approved edition is available to retain"
    )
  })
  httr2::with_mocked_responses(list(httr2::response(status_code = 403)), {
    discovery <- new_discovery(inputs$entry, manifest, inputs$entry$data_url[[1L]])
    discovery$registry_entry <- inputs$entry
    expect_error(
      download_discovered_source(discovery, withr::local_tempdir(), manifest),
      "No approved edition is available to retain"
    )
  })
})

test_that("other HTTP errors and invalid successful downloads still fail", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs()
  httr2::with_mocked_responses(list(httr2::response(status_code = 404)), {
    expect_error(
      discover_source(inputs$entry, inputs$manifest),
      "Discovery failed for `ghs`.*HTTP 404"
    )
  })
  discovery <- new_discovery(inputs$entry, inputs$manifest, inputs$entry$data_url[[1L]])
  discovery$registry_entry <- inputs$entry
  httr2::with_mocked_responses(list(httr2::response(status_code = 401)), {
    expect_error(
      download_discovered_source(discovery, withr::local_tempdir(), inputs$manifest),
      "Download failed for `ghs`.*HTTP 401"
    )
  })
  directory <- withr::local_tempdir()
  # httr2's mock transport does not write the requested output path.
  httr2::with_mocked_responses(function(req) {
    writeLines("<html>Challenge page with HTTP 200</html>", file.path(directory, "ghs.csv"))
    httr2::response()
  }, {
    expect_error(
      download_discovered_source(discovery, directory, inputs$manifest),
      "does not match expected type `csv`"
    )
  })
})

test_that("IMF HTTP 200 error redirects retain approved data and provenance", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs("debt_distress")
  discovery <- discover_source(inputs$entry, inputs$manifest)
  discovery$source_version <- "2099-01-01"
  directory <- withr::local_tempdir()
  httr2::with_mocked_responses(mock_imf_error_redirect(directory), {
    expect_warning(
      path <- download_discovered_source(discovery, directory, inputs$manifest),
      "Source `debt_distress` download.*HTML error page.*HTTP 200.*freshness was not checked"
    )
  })
  expect_true(endsWith(path, ".unavailable.rds"))
  result <- retained_http_result(discovery, path, inputs)
  expected <- inputs$history[
    inputs$history$index_id == "debt_distress" &
      inputs$history$source_version == result$discovery$source_version,
    , drop = FALSE
  ]
  expect_identical(result$data, expected)
  expect_false(result$changed)
  expect_null(result$discovery$content_hash)
  expect_identical(result$validation$status, "WARNING")
  pipeline <- assemble_pipeline(list(result), inputs$history, inputs$manifest)
  expect_false(pipeline$changed)
  expect_identical(pipeline$manifest, inputs$manifest)

  # A previous unavailable marker must not prevent the next run downloading.
  pdf <- charToRaw("%PDF-1.7\nMock IMF debt-distress download\n")
  httr2::with_mocked_responses(function(req) {
    writeBin(pdf, file.path(directory, "debt_distress.pdf"))
    httr2::response(body = pdf)
  }, {
    path <- download_discovered_source(discovery, directory, inputs$manifest)
  })
  expect_identical(readBin(path, "raw", n = length(pdf)), pdf)
  observed <- finalise_discovery(discovery, path, inputs$manifest)
  expect_false(isTRUE(observed$unavailable))
  expect_true(observed$changed)
})

test_that("an IMF error redirect cannot hide a source with no approved edition", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs("debt_distress")
  manifest <- inputs$manifest[inputs$manifest$index_id != "debt_distress", ]
  discovery <- discover_source(inputs$entry, manifest)
  directory <- withr::local_tempdir()
  httr2::with_mocked_responses(mock_imf_error_redirect(directory), {
    expect_error(
      download_discovered_source(discovery, directory, manifest),
      "No approved edition is available to retain"
    )
  })
})

test_that("unrecognized redirects still fail PDF validation", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs("debt_distress")
  discovery <- discover_source(inputs$entry, inputs$manifest)
  directory <- withr::local_tempdir()
  mock <- mock_imf_error_redirect(directory)
  for (url in c(
    "https://example.org/redirect/?URL=$V&404;",
    "https://www.imf.org/redirect/?URL=$V&other;"
  )) {
    httr2::with_mocked_responses(function(req) {
      response <- mock(req)
      response$url <- url
      response
    }, {
      expect_error(
        download_discovered_source(discovery, directory, inputs$manifest),
        "Download failed for `debt_distress`.*does not match expected type `pdf`"
      )
    })
  }
})

test_that("invalid PDF downloads identify the source and URL", {
  skip_if_not(pipeline_available)
  for (index_id in c("debt_distress", "un_mvi")) {
    inputs <- http_pipeline_inputs(index_id)
    discovery <- discover_source(inputs$entry, inputs$manifest)
    directory <- withr::local_tempdir()
    httr2::with_mocked_responses(function(req) {
      writeLines(
        "<!DOCTYPE html><html><body>Error page</body></html>",
        file.path(directory, paste0(index_id, ".pdf"))
      )
      httr2::response(status_code = 200)
    }, {
      error <- tryCatch(
        download_discovered_source(discovery, directory, inputs$manifest),
        error = identity
      )
    })
    expect_s3_class(error, "error")
    expect_match(
      conditionMessage(error),
      paste0("Download failed for `", index_id, "` at ", discovery$url),
      fixed = TRUE
    )
    expect_match(conditionMessage(error), "does not match expected type `pdf`")
  }
})

test_that("an unavailable source does not prevent another validated source update", {
  skip_if_not(pipeline_available)
  inputs <- http_pipeline_inputs()
  directory <- withr::local_tempdir()
  httr2::with_mocked_responses(list(httr2::response(status_code = 403)), {
    expect_warning(
      discovery <- discover_source(inputs$entry, inputs$manifest),
      "HTTP 403"
    )
  })
  blocked <- retained_http_result(
    discovery,
    download_discovered_source(discovery, directory, inputs$manifest),
    inputs
  )
  hdi <- http_pipeline_inputs("hdi")
  updated <- new_discovery(hdi$entry, hdi$manifest, hdi$entry$data_url[[1L]])
  updated$registry_entry <- hdi$entry
  candidate <- current_history_views(hdi$history, hdi$manifest)
  candidate <- candidate[candidate$index_id == "hdi", , drop = FALSE]
  candidate$source_version <- paste0(updated$source_version, "+test")
  updated$source_version <- candidate$source_version[[1L]]
  updated$changed <- TRUE
  updated$content_hash <- "test-content-hash"
  updated$source_file <- file.path(directory, "hdi.csv")
  result <- build_source_result(
    candidate, list(discovery = updated),
    validate_source_candidate(candidate, updated),
    compare_source_candidate(candidate, hdi$history, hdi$manifest)
  )
  pipeline <- assemble_pipeline(
    list(blocked, result), inputs$history, inputs$manifest
  )
  expect_true(pipeline$changed)
  expect_length(pipeline$changed_sources, 1L)
  expect_identical(pipeline$changed_sources[[1L]]$discovery$index_id, "hdi")
  # Appending a manifest entry can coerce an all-NA logical column to text;
  # compare the persisted values of the retained provenance.
  expect_identical(
    lapply(pipeline$manifest[pipeline$manifest$index_id == "ghs", ], as.character),
    lapply(inputs$manifest[inputs$manifest$index_id == "ghs", ], as.character)
  )
  expect_equal(nrow(pipeline$history), nrow(inputs$history) + 195L)
  report <- file.path(directory, "summary.md")
  write_update_report(pipeline, report)
  expect_match(paste(readLines(report), collapse = "\n"), "Source `ghs` discovery")

  result$validation <- validation_result("FAIL", "Invalid candidate")
  expect_error(
    assemble_pipeline(list(blocked, result), inputs$history, inputs$manifest),
    "Pipeline validation failed"
  )
})
