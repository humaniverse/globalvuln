fixture_discovery <- function(index_id, url = NULL) {
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  entry <- registry_entry(registry, index_id)
  current <- manifest[manifest$index_id == index_id, , drop = FALSE]
  list(
    index_id = index_id,
    registry_entry = entry,
    url = url %||% entry$data_url[[1L]] %||% entry$homepage_url[[1L]],
    publication_date = as.Date(NA),
    source_version = current$source_version[[nrow(current)]]
  )
}

write_fixture_xlsx <- function(data, sheet, col_names = FALSE) {
  testthat::skip_if_not_installed("writexl")
  path <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(
    stats::setNames(list(as.data.frame(data, stringsAsFactors = FALSE)), sheet),
    path,
    col_names = col_names
  )
  path
}

test_that("landing-page discovery selects machine-readable release links", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  document <- rvest::read_html(paste0(
    '<html><a href="/files/WorldRiskIndex-2024.xlsx">2024 data</a>',
    '<a href="/files/WorldRiskIndex-2025.xlsx">2025 data</a>',
    '<a href="/files/WorldRiskIndex-meta-2025.xlsx">metadata</a></html>'
  ))
  candidates <- landing_file_candidates(
    document,
    "WorldRiskIndex[-_ ]?20[0-9]{2}.*[.]xlsx",
    "meta|trend"
  )
  years <- vapply(candidates, discovery_sort_year, integer(1))
  expect_identical(candidates[[which.max(years)]], "/files/WorldRiskIndex-2025.xlsx")
  expect_identical(
    absolute_source_url(candidates[[which.max(years)]], "https://example.org/releases/"),
    "https://example.org/files/WorldRiskIndex-2025.xlsx"
  )
})

test_that("INFORM Risk workbook fields and version are parsed", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  raw <- matrix("", nrow = 4L, ncol = 3L)
  raw[3L, ] <- c("Afghanistan", "AFG", "7.8")
  raw[4L, ] <- c("Albania", "ALB", "3.1")
  path <- write_fixture_xlsx(raw, "INFORM Risk 2026 (a-z)")
  parsed <- parse_inform_risk(
    path,
    fixture_discovery("inform_risk", "https://example.org/INFORM_Risk_2026_v072.xlsx")
  )
  expect_identical(parsed$source_version, "2026 v0.7.2")
  expect_identical(parsed$data$iso3, c("AFG", "ALB"))
  expect_equal(parsed$data$score, c(7.8, 3.1))
})

test_that("Underfunded Crisis embedded payload excludes regional plans", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  payload <- list(x = list(tag = list(attribs = list(data = data.frame(
    context = c("Afghanistan", "Regional: Syria RRP"),
    cum_percent_met = c(0.6724323, 0.25)
  )))))
  html <- paste0(
    '<html><script type="application/json">',
    jsonlite::toJSON(payload, auto_unbox = TRUE, dataframe = "columns", digits = NA),
    "</script></html>"
  )
  path <- tempfile(fileext = ".html")
  writeLines(html, path, useBytes = TRUE)
  parsed <- parse_underfunded_crisis(
    path,
    fixture_discovery("underfunded_crisis", "https://example.org/underfundingtable25.html")
  )
  expect_identical(parsed$data$source_country, "Afghanistan")
  expect_equal(parsed$data$score, 67.24323)
  expect_identical(parsed$data$score_label, "67.2%")
})

test_that("OECD fragility TSV preserves decimal-comma scores", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  path <- tempfile(fileext = ".tsv")
  writeLines(c(
    "country\tiso3\toverall",
    "Afghanistan\tAFG\t-4,395216",
    "Angola\tAGO\t-2,535993"
  ), path)
  parsed <- parse_oecd_fragility(path, fixture_discovery("oecd_fragility"))
  expect_equal(parsed$data$score, c(-4.395216, -2.535993))
  expect_identical(parsed$reference_period, "predominantly 2023")
})

test_that("WorldRiskIndex workbook uses the first three publisher columns", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  path <- write_fixture_xlsx(
    data.frame(country = "Afghanistan", iso3 = "AFG", score = 3.7),
    "WorldRiskIndex",
    col_names = TRUE
  )
  parsed <- parse_worldrisk(path, fixture_discovery("worldrisk"))
  expect_identical(parsed$source_version, "2025")
  expect_equal(parsed$data$score, 3.7)
})

test_that("ND-GAIN ZIP selects the latest annual overall score", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  testthat::skip_if_not_installed("zip")
  root <- tempfile("nd-gain-fixture-")
  dir.create(file.path(root, "ndgain", "gain"), recursive = TRUE)
  utils::write.csv(
    data.frame(Name = "Afghanistan", ISO3 = "AFG", `2023` = 32, `2024` = 33.02413, check.names = FALSE),
    file.path(root, "ndgain", "gain", "gain.csv"),
    row.names = FALSE
  )
  path <- tempfile(fileext = ".zip")
  zip::zip(path, "ndgain/gain/gain.csv", root = root)
  parsed <- parse_nd_gain(
    path,
    fixture_discovery("nd_gain", "https://example.org/ndgain_countryindex_2026.zip")
  )
  expect_identical(parsed$reference_period, "2024")
  expect_equal(parsed$data$score, 33.02413)
})

test_that("HDI CSV selects the latest HDI year and drops aggregates", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  path <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(
    country = c("Afghanistan", "World"),
    iso3 = c("AFG", "World"),
    hdi_2022 = c(0.49, 0.7),
    hdi_2023 = c(0.496, 0.71)
  ), path, row.names = FALSE)
  parsed <- parse_hdi(
    path,
    fixture_discovery("hdi", "https://example.org/2025_HDR/HDR25_Composite_indices_complete_time_series.csv")
  )
  expect_identical(parsed$data$iso3, "AFG")
  expect_equal(parsed$data$score, 0.496)
  expect_identical(parsed$reference_period, "2023")
})

test_that("Global MPI workbook preserves country-specific survey years", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  raw <- matrix("", nrow = 10L, ncol = 4L)
  raw[8L, ] <- c("Afghanistan", "2022/2023 M", "", "0.3603053")
  raw[9L, ] <- c("Developing countries", "", "", "0.1")
  path <- write_fixture_xlsx(raw, "gMPI_Table1")
  parsed <- parse_mpi(
    path,
    fixture_discovery("mpi", "https://example.org/2025_gMPI_Table1and2.xlsx")
  )
  expect_identical(parsed$data$source_country, "Afghanistan")
  expect_identical(parsed$data$reference_year, "2022/2023 M")
  expect_equal(parsed$data$score, 0.3603053)
})

test_that("GHI HTML retains censored labels without inventing scores", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  html <- paste0(
    "<html><h1>Global Hunger Index Scores by 2025 GHI Rank</h1><table>",
    "<tr><td>1</td><td><a>Afghanistan</a></td><td></td><td></td><td></td><td>29.0</td></tr>",
    "<tr><td>2</td><td><a>Armenia</a></td><td></td><td></td><td></td>",
    '<td><span class="stealth">2.5</span>&lt;5</td></tr></table></html>'
  )
  path <- tempfile(fileext = ".html")
  writeLines(html, path, useBytes = TRUE)
  parsed <- parse_ghi(path, fixture_discovery("ghi"))
  expect_equal(parsed$data$score, c(29, NA))
  expect_identical(parsed$data$score_label, c("29.0", "<5"))
})

test_that("GHI download preparation removes unrelated dynamic page markup", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  rows <- paste(rep(
    "<tr><td>1</td><td>Country</td><td></td><td></td><td></td><td>10.0</td></tr>",
    80L
  ), collapse = "")
  table <- paste0("<table>", rows, "</table>")
  paths <- c(tempfile(fileext = ".html"), tempfile(fileext = ".html"))
  writeLines(paste0("<html><div>request-a</div>", table, "</html>"), paths[[1L]])
  writeLines(paste0("<html><div>request-b</div>", table, "</html>"), paths[[2L]])
  invisible(lapply(paths, prepare_source_file_ghi, discovery = fixture_discovery("ghi")))
  hashes <- vapply(paths, digest::digest, character(1), file = TRUE, algo = "sha256")
  expect_identical(hashes[[1L]], hashes[[2L]])
})

test_that("GHS CSV selects the latest edition", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  path <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(
    Country = c("Afghanistan", "Afghanistan"),
    Year = c(2019, 2021),
    `OVERALL SCORE` = c(25, 28.8),
    check.names = FALSE
  ), path, row.names = FALSE)
  parsed <- parse_ghs(path, fixture_discovery("ghs"))
  expect_identical(parsed$source_version, "2021")
  expect_equal(parsed$data$score, 28.8)
})

test_that("WPS workbook reads country ISO3 and composite score", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  raw <- matrix("", nrow = 8L, ncol = 5L)
  raw[7L, ] <- c("1", "Afghanistan", "AFG", "181", "0.279")
  path <- write_fixture_xlsx(raw, "TABLE 1")
  parsed <- parse_wps(
    path,
    fixture_discovery("wps", "https://example.org/WPS-Index-2025-Data.xlsx")
  )
  expect_identical(parsed$source_version, "2025/26")
  expect_equal(parsed$data$score, 0.279)
})

test_that("UN MVI PDF text parser selects the overall index column", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  parsed <- parse_un_mvi_text(
    "Afghanistan AFG 54.9 30.0 20.0\nAlgeria DZA 53.3 29.0 19.0",
    fixture_discovery("un_mvi")
  )
  expect_identical(parsed$data$iso3, c("AFG", "DZA"))
  expect_equal(parsed$data$score, c(54.9, 53.3))
})

test_that("SEARO workbook reads December release metadata", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  raw <- matrix("", nrow = 6L, ncol = 5L)
  raw[5L, ] <- c("Afghanistan", "", "AFG", "", "7.221153")
  path <- write_fixture_xlsx(raw, "SEARO")
  parsed <- parse_searo(path, fixture_discovery("searo"))
  expect_identical(parsed$source_version, "2026 v1.2")
  expect_identical(parsed$reference_period, "December 2025")
  expect_equal(parsed$data$score, 7.221153)
})

test_that("manual disaster-displacement export enforces its acquisition contract", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  path <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(
    iso3 = c("AFG", "ALB"),
    country = c("Afghanistan", "Albania"),
    aad_current_multihazard = c(100, 50),
    scenario = "Current",
    metric = "AAD",
    hazard_scope = "Multi-hazard",
    source_snapshot_date = "2026-08-25",
    aggregation_level = "Country",
    notes = "fixture"
  ), path, row.names = FALSE)
  parsed <- parse_disaster_displacement(
    path,
    fixture_discovery("disaster_displacement", "https://example.org/manual.csv")
  )
  expect_identical(parsed$source_version, "GDRM 2.0")
  expect_equal(parsed$data$score, c(100, 50))
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  overrides <- read_country_overrides(pipeline_path(
    "data-raw", "overrides", "countries.csv"
  ))
  discovery <- fixture_discovery(
    "disaster_displacement",
    "https://example.org/manual.csv"
  )
  candidate <- standardise_source(parsed, discovery, history, overrides)
  expect_identical(nrow(candidate), 195L)
  expect_identical(validate_source_candidate(candidate, discovery)$status, "PASS")
})

test_that("Internal Displacement Index workbook reads the composite column", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  raw <- matrix("", nrow = 5L, ncol = 46L)
  raw[4L, 1L] <- "AFG"
  raw[4L, 3L] <- "Afghanistan"
  raw[4L, 46L] <- "0.743427"
  path <- write_fixture_xlsx(raw, "IDI 2022 values ")
  parsed <- parse_internal_displacement(path, fixture_discovery("internal_displacement"))
  expect_identical(parsed$source_version, "IDI 2023 publication")
  expect_equal(parsed$data$score, 0.743427)
})

test_that("every automated adapter satisfies the canonical contract offline", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  history <- read_approved_history(pipeline_path(
    "data-raw", "approved", "humanitarian_indices.rds"
  ))
  manifest <- read_approved_manifest(pipeline_path(
    "data-raw", "approved", "source_manifest.csv"
  ))
  current <- current_history_views(history, manifest)
  overrides <- read_country_overrides(pipeline_path(
    "data-raw", "overrides", "countries.csv"
  ))

  for (index_id in registry$index_id[registry$automated]) {
    expected <- current[current$index_id == index_id, , drop = FALSE]
    covered <- !is.na(expected$source_country)
    parsed <- list(
      data = expected[covered, c(
        "source_country", "iso3", "score", "score_label", "reference_year"
      )],
      source_version = unique(expected$source_version)[[1L]],
      edition = unique(expected$edition)[[1L]],
      reference_period = unique(expected$reference_period)[[1L]],
      publication_date = unique(expected$publication_date)[[1L]],
      methodology_version = unique(expected$methodology_version)[[1L]]
    )
    if (index_id == "debt_distress") {
      parsed$data$latest_dsa_label <- parsed$data$reference_year
    }
    discovery <- fixture_discovery(index_id)
    candidate <- standardise_source(parsed, discovery, history, overrides)
    expect_identical(nrow(candidate), 195L, info = index_id)
    expect_true(all(canonical_columns %in% names(candidate)), info = index_id)
    expect_identical(
      validate_source_candidate(candidate, discovery)$status,
      "PASS",
      info = index_id
    )
  }
})
