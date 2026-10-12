test_that("INFORM Severity fixture satisfies the adapter contract", {
  skip_if_not(pipeline_available, "data-raw pipeline is excluded from the built package")
  registry <- read_source_registry(pipeline_path("data-raw", "sources.yml"))
  discovery <- list(
    registry_entry = registry_entry(registry, "inform_severity")
  )
  parsed <- parse_inform_severity(
    testthat::test_path("fixtures", "inform-severity.xlsx"),
    discovery
  )

  expect_identical(parsed$source_version, "2026-06")
  expect_identical(parsed$data$iso3, c("AFG", "BDI", "BEN"))
  expect_equal(parsed$data$score, c(9.2, 4.9, 4.6))
})

inform_severity_duplicate_fixture <- function() {
  list(
    rows = data.frame(
      CRISIS = c("Conflict in Papua", "Multiple crises in Indonesia", "Complex crisis in Afghanistan"),
      `CRISIS ID` = c("IDN002", "IDN007", "AFG001"),
      COUNTRY = c("Indonesia", "Indonesia", "Afghanistan"),
      ISO3 = c("IDN", "IDN", "AFG"),
      `INFORM Severity Index` = c("5.4", "5.3", "9.2"),
      check.names = FALSE
    ),
    metadata = data.frame(
      `Crisis ID` = c("IDN002", "IDN007", "AFG001"),
      Crisis = c("Conflict in Papua", "Multiple crises in Indonesia", "Complex crisis in Afghanistan"),
      `ISO3 code` = c("IDN", "IDN", "AFG"),
      Geoscope = c("Subnational", "National", "National"),
      check.names = FALSE
    )
  )
}

write_inform_severity_test_workbook <- function(rows, metadata = NULL) {
  skip_if_not_installed("writexl")
  country <- rbind(
    c("INFORM Severity - country", rep("", ncol(rows) - 1L)),
    names(rows), as.matrix(rows)
  )
  sheets <- list(
    About = data.frame(text = c("release:", "31/08/2026", "INFORM SEVERITY INDEX", "August 2026")),
    `INFORM Severity - country` = as.data.frame(country)
  )
  if (!is.null(metadata)) {
    sheets[["Crisis info"]] <- as.data.frame(rbind(names(metadata), as.matrix(metadata)))
  }
  path <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(sheets, path, col_names = FALSE)
  path
}

test_that("INFORM Severity uses the verified country aggregate rather than the highest crisis", {
  skip_if_not(pipeline_available)
  fixture <- inform_severity_duplicate_fixture()
  path <- write_inform_severity_test_workbook(fixture$rows, fixture$metadata)
  parsed <- parse_inform_severity(path, NULL)
  expect_identical(parsed$source_version, "2026-08")
  expect_identical(parsed$data$iso3, c("IDN", "AFG"))
  expect_equal(parsed$data$score, c(5.3, 9.2))
  expect_false(anyDuplicated(parsed$data$iso3) > 0L)

  # The same national score must be selected regardless of row order.
  reordered <- write_inform_severity_test_workbook(
    fixture$rows[c(2L, 1L, 3L), ], fixture$metadata[c(3L, 1L, 2L), ]
  )
  expect_identical(parse_inform_severity(reordered, NULL)$data, parsed$data)
})

test_that("INFORM Severity rejects duplicates without a unique country aggregate", {
  skip_if_not(pipeline_available)
  fixture <- inform_severity_duplicate_fixture()
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(fixture$rows), NULL),
    "ambiguous duplicate ISO3 codes \\(IDN\\).*metadata are required"
  )
  no_aggregate <- fixture$metadata
  no_aggregate$Geoscope[2L] <- "Subnational"
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(fixture$rows, no_aggregate), NULL),
    "exactly one national Multiple Crises country aggregate"
  )
  rows <- rbind(fixture$rows, fixture$rows[2L, ])
  rows[["CRISIS ID"]][4L] <- "IDN008"
  metadata <- rbind(fixture$metadata, fixture$metadata[2L, ])
  metadata[["Crisis ID"]][4L] <- "IDN008"
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(rows, metadata), NULL),
    "exactly one national Multiple Crises country aggregate"
  )
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(
      fixture$rows[, names(fixture$rows) != "CRISIS ID"], fixture$metadata
    ), NULL),
    "crisis identifiers.*required"
  )
})

test_that("INFORM Severity requires crisis metadata to agree with duplicated country rows", {
  skip_if_not(pipeline_available)
  fixture <- inform_severity_duplicate_fixture()
  for (field in c("ISO3 code", "Crisis")) {
    metadata <- fixture$metadata
    metadata[[field]][2L] <- "does not match"
    expect_error(
      parse_inform_severity(write_inform_severity_test_workbook(fixture$rows, metadata), NULL),
      "metadata does not match"
    )
  }
  metadata <- rbind(fixture$metadata, fixture$metadata[2L, ])
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(fixture$rows, metadata), NULL),
    "exactly one metadata record"
  )
  metadata <- fixture$metadata[-2L, ]
  expect_error(
    parse_inform_severity(write_inform_severity_test_workbook(fixture$rows, metadata), NULL),
    "exactly one metadata record"
  )
})
