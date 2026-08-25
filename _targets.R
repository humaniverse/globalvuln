library(targets)

source(file.path("R", "common-schema.R"))
pipeline_files <- list.files(
  file.path("data-raw", "R"),
  pattern = "[.]R$",
  full.names = TRUE
)
invisible(lapply(pipeline_files, source))

tar_option_set(
  packages = c(
    "countrycode", "digest", "httr2", "jsonlite", "pdftools", "pins", "readxl",
    "rvest", "yaml"
  ),
  error = "stop",
  garbage_collection = TRUE
)

list(
  tar_target(
    registry_file,
    file.path("data-raw", "sources.yml"),
    format = "file"
  ),
  tar_target(source_registry, read_source_registry(registry_file)),
  tar_target(
    validated_registry,
    validate_source_registry(source_registry, .index_ids)
  ),
  tar_target(
    approved_history_file,
    file.path("data-raw", "approved", "humanitarian_indices.rds"),
    format = "file"
  ),
  tar_target(approved_history, read_approved_history(approved_history_file)),
  tar_target(
    approved_manifest_file,
    file.path("data-raw", "approved", "source_manifest.csv"),
    format = "file"
  ),
  tar_target(approved_manifest, read_approved_manifest(approved_manifest_file)),
  tar_target(
    country_overrides_file,
    file.path("data-raw", "overrides", "countries.csv"),
    format = "file"
  ),
  tar_target(country_overrides, read_country_overrides(country_overrides_file)),
  tar_target(
    source_entry,
    automated_registry_entries(validated_registry),
    iteration = "list"
  ),
  tar_target(
    discovery,
    discover_source(source_entry, approved_manifest),
    pattern = map(source_entry),
    iteration = "list",
    cue = tar_cue(mode = "always")
  ),
  tar_target(
    source_file,
    download_discovered_source(discovery),
    pattern = map(discovery),
    format = "file"
  ),
  tar_target(
    observed_discovery,
    finalise_discovery(discovery, source_file, approved_manifest),
    pattern = map(discovery, source_file),
    iteration = "list"
  ),
  tar_target(
    parsed_source,
    parse_source_file(source_file, observed_discovery, approved_manifest),
    pattern = map(source_file, observed_discovery),
    iteration = "list"
  ),
  tar_target(
    standardised_source,
    standardise_source(
      parsed_source,
      parsed_source$discovery,
      approved_history,
      country_overrides
    ),
    pattern = map(parsed_source),
    iteration = "list"
  ),
  tar_target(
    source_validation,
    validate_source_candidate(standardised_source, parsed_source$discovery),
    pattern = map(standardised_source, parsed_source),
    iteration = "list"
  ),
  tar_target(
    source_comparison,
    compare_source_candidate(
      standardised_source,
      approved_history,
      approved_manifest
    ),
    pattern = map(standardised_source),
    iteration = "list"
  ),
  tar_target(
    source_result,
    build_source_result(
      standardised_source,
      parsed_source,
      source_validation,
      source_comparison
    ),
    pattern = map(
      standardised_source,
      parsed_source,
      source_validation,
      source_comparison
    ),
    iteration = "list"
  ),
  tar_target(
    pipeline_result,
    assemble_pipeline(source_result, approved_history, approved_manifest)
  ),
  tar_target(
    published_files,
    publish_pipeline(pipeline_result),
    format = "file"
  )
)
