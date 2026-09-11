clif_vi_discovery <- function() {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discover_source(registry_entry(registry, "clif_vi"), data.frame(index_id = character()))
}

clif_vi_fixture_rows <- function() {
  list(
    list(country_name = "Norway", country_code = "NOR",
         `2050_pessimistic_final_value` = "5.261234", `2050_optimistic_final_value` = "99",
         `2080_pessimistic_final_value` = "98", `2050_pessimistic_rank_number` = "1"),
    list(country_name = "Guinea-Bissau", country_code = "GNB",
         `2050_pessimistic_final_value` = "90.92", financial_vulnerability_index = "1")
  )
}

write_clif_vi_fixture <- function(rows = clif_vi_fixture_rows(), noise = "first") {
  directory <- withr::local_tempdir(.local_envir = parent.frame())
  path <- file.path(directory, "source.html")
  payload <- jsonlite::toJSON(
    list(baseData = list(countryData = rows, geoData = noise), pageID = noise),
    auto_unbox = TRUE, digits = NA, null = "null"
  )
  writeLines(paste0(
    '<html><meta name="timestamp" content="', noise, '">',
    '<script id="charts-js-extra">\nvar charts = ', payload,
    ';\n//# sourceURL=charts-js-extra\n</script><script>throw "never execute";</script></html>'
  ), path, useBytes = TRUE)
  path
}

test_that("CliF-VI selects the fixed source and exact 2050 pessimistic score", {
  discovery <- clif_vi_discovery()
  expect_identical(discovery$url, "https://clifvi.org/")
  parsed <- parse_clif_vi(write_clif_vi_fixture(), discovery)
  expect_identical(parsed$data$iso3, c("GNB", "NOR"))
  expect_equal(parsed$data$score, c(90.92, 5.261234))
  expect_identical(parsed$edition, "2025 prototype (2050 pessimistic)")
  expect_identical(parsed$reference_period, "2050 (pessimistic projection)")
  expect_identical(parsed$methodology_version, "June 2025")
  expect_true(is.na(parsed$publication_date))
  expect_true(all(is.na(parsed$data$score_label)))
})

test_that("CliF-VI fails on changed payloads, country keys, and non-numeric scores", {
  discovery <- clif_vi_discovery()
  path <- write_clif_vi_fixture()
  writeLines('<html><script id="charts-js-extra">var charts = {broken};</script></html>', path)
  expect_error(parse_clif_vi(path, discovery), "malformed JSON")
  writeLines('<html><script id="charts-js-extra">alert(1)</script></html>', path)
  expect_error(parse_clif_vi(path, discovery), "unrecognised assignment")
  writeLines('<html><script id="charts-js-extra">var charts = {};</script></html>', path)
  expect_error(parse_clif_vi(path, discovery), "missing baseData.countryData")
  writeLines('<html>error page</html>', path)
  expect_error(parse_clif_vi(path, discovery), "exactly one")
  expect_error(parse_clif_vi(write_clif_vi_fixture(list()), discovery), "non-empty country array")
  rows <- clif_vi_fixture_rows()
  rows[[1L]][["2050_pessimistic_final_value"]] <- NULL
  expect_error(parse_clif_vi(write_clif_vi_fixture(rows), discovery), "2050_pessimistic_final_value")
  for (value in list("not available", "Inf", "NaN", TRUE, c(1, 2))) {
    rows <- clif_vi_fixture_rows()
    rows[[1L]][["2050_pessimistic_final_value"]] <- value
    expect_error(parse_clif_vi(write_clif_vi_fixture(rows), discovery), "numeric score|must be numeric")
  }
  rows <- clif_vi_fixture_rows()
  rows[[1L]]$country_code <- "World"
  expect_error(parse_clif_vi(write_clif_vi_fixture(rows), discovery), "invalid ISO3")
  rows[[1L]]$country_code <- "gnb"
  expect_error(parse_clif_vi(write_clif_vi_fixture(rows), discovery), "duplicate country")
  rows[[1L]]$country_name <- ""
  expect_error(parse_clif_vi(write_clif_vi_fixture(rows), discovery), "non-empty strings")
})

test_that("CliF-VI hashes ignore page noise and detect selected-score revisions", {
  discovery <- clif_vi_discovery()
  hash_prepared <- function(path) {
    prepared <- prepare_source_file_clif_vi(path, discovery)
    expect_no_error(validate_download_signature(prepared, "html"))
    digest::digest(file = prepared, algo = "sha256", serialize = FALSE)
  }
  first <- write_clif_vi_fixture()
  original <- hash_prepared(first)
  rows <- rev(clif_vi_fixture_rows())
  rows[[2L]][["2050_optimistic_final_value"]] <- "2"
  second <- write_clif_vi_fixture(rows, noise = "changed")
  expect_identical(hash_prepared(second), original)
  rows[[1L]][["2050_pessimistic_final_value"]] <- "90.93"
  expect_false(identical(hash_prepared(write_clif_vi_fixture(rows)), original))
  prepared <- prepare_source_file_clif_vi(first, discovery)
  expect_false(as.raw(13L) %in% readBin(prepared, "raw", n = file.info(prepared)$size))
  expect_identical(parse_clif_vi(prepared, discovery), parse_clif_vi(first, discovery))
  unicode_rows <- clif_vi_fixture_rows()
  unicode_rows[[1L]]$country_name <- "\u00c9xample <country>"
  unicode_file <- write_clif_vi_fixture(unicode_rows)
  unicode_prepared <- prepare_source_file_clif_vi(unicode_file, discovery)
  expect_identical(parse_clif_vi(unicode_prepared, discovery), parse_clif_vi(unicode_file, discovery))
  expect_identical(read_clif_vi_countries(unicode_prepared)$country_name[[2L]], "\u00c9xample <country>")

  observed <- finalise_discovery(discovery, prepared, data.frame(index_id = character()))
  expect_true(observed$changed)
  approved <- data.frame(index_id = "clif_vi", source_version = "2025 prototype (2050 pessimistic)",
                         source_content_hash = observed$content_hash)
  discovery$source_version <- approved$source_version
  repeated <- finalise_discovery(discovery, prepared, approved)
  expect_false(repeated$changed)
  revised <- finalise_discovery(discovery,
    prepare_source_file_clif_vi(write_clif_vi_fixture(rows), discovery), approved)
  parsed_revision <- parse_source_file(revised$source_file, revised, approved)
  expect_true(parsed_revision$discovery$revision)
  expect_match(parsed_revision$source_version, "[+][0-9a-f]{8}$")
})

test_that("CliF-VI validates geography, numeric coverage, scenario, and score range", {
  discovery <- clif_vi_discovery()
  history <- read_approved_history(pipeline_path("data-raw", "approved", "humanitarian_indices.rds"))
  geography <- master_geography_from_history(history)
  selected <- geography[seq_len(188L), ]
  rows <- lapply(seq_len(188L), function(i) list(
    country_name = selected$country[[i]], country_code = selected$iso3[[i]],
    `2050_pessimistic_final_value` = (i - 1) / 2
  ))
  parsed <- parse_clif_vi(write_clif_vi_fixture(rows), discovery)
  candidate <- standardise_clif_vi(parsed, discovery, geography, data.frame())
  expect_identical(dim(candidate), c(195L, 25L))
  expect_false(anyDuplicated(candidate$iso3) > 0L)
  expect_identical(validate_source_candidate(candidate, discovery)$status, "PASS")
  expect_equal(candidate$rank[candidate$score == 93.5 & !is.na(candidate$score)], 1L)
  expect_true(all(is.na(candidate$rank[is.na(candidate$score)])))
  for (invalid in c(-1, 101, Inf)) {
    changed <- candidate
    changed$score[[1L]] <- invalid
    expect_identical(validate_clif_vi(changed, discovery)$status, "FAIL")
  }
  changed <- candidate
  changed$score[[1L]] <- NA_real_
  expect_identical(validate_clif_vi(changed, discovery)$status, "FAIL")
  changed <- candidate
  changed$reference_period <- "2080 (pessimistic projection)"
  expect_identical(validate_clif_vi(changed, discovery)$status, "FAIL")
  parsed$data$iso3[[1L]] <- "WLD"
  expect_error(standardise_clif_vi(parsed, discovery, geography, data.frame()), "Unexpected non-master ISO3")

  rows[[1L]]["2050_pessimistic_final_value"] <- list(NULL)
  missing <- parse_clif_vi(write_clif_vi_fixture(rows), discovery)
  expect_equal(sum(is.na(missing$data$score)), 1L)
})

test_that("CliF-VI bundled and board APIs preserve coverage and summary participation", {
  environment <- new.env(parent = emptyenv())
  utils::data("clif_vi", package = "globalvuln", envir = environment)
  bundled <- environment$clif_vi
  expect_equal(sum(!is.na(bundled$score)), 188L)
  expect_setequal(bundled$iso3[is.na(bundled$score)], c("AND", "CUB", "PRK", "VAT", "LIE", "MCO", "SMR"))
  expect_equal(bundled$score[match(c("AFG", "NOR", "GNB"), bundled$iso3)], c(52.18, 5.26, 90.92))
  expect_equal(bundled$rank[bundled$iso3 == "GNB"], 1L)
  expect_identical(bundled$source_country[match(c("CIV", "TUR"), bundled$iso3)],
    c("C\u00f4te d&#8217;Ivoire", "T\u00fcrkiye"))
  long <- collate_indices("clif_vi", format = "long")
  wide <- collate_indices("clif_vi")
  expect_equal(nrow(long), 195L)
  expect_equal(wide$clif_vi_score, long$score)
  expect_equal(wide$top_10_count[wide$iso3 == "GNB"], 1L)
  expect_equal(wide$indices_ranked_count[wide$iso3 == "AND"], 0L)
  expect_equal(wide$top_20_proportion[wide$iso3 == "GNB"], 1)
  package <- globalvuln_data(source = "package", indices = "clif_vi")
  expect_equal(package$score, bundled$score)
  status <- source_status(source = "package")
  expect_true("clif_vi" %in% status$index_id)
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  withr::local_options(globalvuln.board_url = pipeline_path("data-published"))
  latest <- globalvuln_data(source = "latest", indices = "clif_vi")
  expect_equal(latest$score, bundled$score)
  latest_wide <- globalvuln_data(source = "latest", indices = "clif_vi", format = "wide")
  expect_equal(latest_wide$clif_vi_score, wide$clif_vi_score)
})
