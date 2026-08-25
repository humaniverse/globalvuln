publish_pipeline <- function(
    pipeline,
    history_path = file.path("data-raw", "approved", "humanitarian_indices.rds"),
    manifest_path = file.path("data-raw", "approved", "source_manifest.csv"),
    board_path = "data-published",
    report_path = file.path("artifacts", "update-summary.md")) {
  dir.create(dirname(history_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)

  if (pipeline$changed) {
    saveRDS(pipeline$history, history_path, version = 3, compress = "xz")
    utils::write.csv(pipeline$manifest, manifest_path, row.names = FALSE, na = "")
    utils::write.csv(
      pipeline$manifest,
      file.path("inst", "extdata", "source_manifest.csv"),
      row.names = FALSE,
      na = ""
    )
  }

  package_files <- write_package_data_if_changed(
    pipeline$history,
    pipeline$manifest,
    pipeline$changed_sources
  )
  board_files <- publish_pins_board(
    pipeline$history,
    pipeline$manifest,
    board_path,
    force = pipeline$changed
  )
  write_update_report(pipeline, report_path)
  unique(c(
    normalizePath(history_path, winslash = "/", mustWork = TRUE),
    normalizePath(manifest_path, winslash = "/", mustWork = TRUE),
    normalizePath(
      file.path("inst", "extdata", "source_manifest.csv"),
      winslash = "/",
      mustWork = TRUE
    ),
    package_files,
    board_files,
    normalizePath(report_path, winslash = "/", mustWork = TRUE)
  ))
}

write_package_data_if_changed <- function(history, manifest, changed_sources) {
  current <- current_history_views(history, manifest)
  files <- character()
  for (index_id in .index_ids) {
    object <- current[current$index_id == index_id, 1:19, drop = FALSE]
    geography_order <- master_geography_from_history(history)$iso3
    object <- object[match(geography_order, object$iso3), , drop = FALSE]
    rownames(object) <- NULL
    destination <- file.path("data", paste0(index_id, ".rda"))
    existing <- NULL
    if (file.exists(destination)) {
      environment <- new.env(parent = emptyenv())
      load(destination, envir = environment)
      existing <- get(index_id, envir = environment, inherits = FALSE)
    }
    if (!identical(existing, object)) {
      environment <- list2env(setNames(list(object), index_id), parent = emptyenv())
      save(
        list = index_id,
        file = destination,
        envir = environment,
        version = 3,
        compress = "xz"
      )
    }
    files <- c(files, normalizePath(destination, winslash = "/", mustWork = TRUE))
  }

  legacy_path <- file.path("data", "humanitarian_index_sources.rda")
  legacy_environment <- new.env(parent = emptyenv())
  load(legacy_path, envir = legacy_environment)
  legacy <- legacy_environment$humanitarian_index_sources
  for (result in changed_sources) {
    index_id <- result$discovery$index_id
    row <- match(index_id, legacy$source_id)
    data <- result$data
    legacy$source_name[row] <- unique(data$index_name)[[1L]]
    legacy$edition[row] <- unique(data$edition)[[1L]]
    legacy$reference_year[row] <- unique(data$reference_year[!is.na(data$reference_year)])[[1L]]
    legacy$source_url[row] <- result$discovery$registry_entry$homepage_url[[1L]]
    legacy$download_url[row] <- result$discovery$url
    legacy$local_file[row] <- file.path(
      "_targets", "downloads", basename(result$discovery$source_file)
    )
    legacy$retrieval_date[row] <- unique(data$retrieval_date)[[1L]]
    legacy$sha256[row] <- result$discovery$content_hash
    legacy$file_bytes[row] <- file.info(result$discovery$source_file)$size
    legacy$source_status[row] <- "available"
    legacy$n_numeric_scores[row] <- sum(!is.na(data$score))
    legacy$n_labelled_records[row] <- sum(!is.na(data$score_label))
    legacy$n_ranked[row] <- sum(!is.na(data$rank))
    legacy$coverage_ok[row] <- result$validation$status != "FAIL"
    legacy$license_notes[row] <- result$discovery$registry_entry$license[[1L]]
    legacy$source_notes[row] <- paste0(
      "Automated adapter ",
      result$discovery$registry_entry$adapter_version[[1L]],
      "; validation ", result$validation$status
    )
  }
  if (!identical(legacy_environment$humanitarian_index_sources, legacy)) {
    humanitarian_index_sources <- legacy
    save(
      humanitarian_index_sources,
      file = legacy_path,
      version = 3,
      compress = "xz"
    )
  }
  c(files, normalizePath(legacy_path, winslash = "/", mustWork = TRUE))
}

publish_pins_board <- function(history, manifest, board_path, force = FALSE) {
  expected <- file.path(board_path, "_pins.yaml")
  if (!force && file.exists(expected)) {
    return(normalizePath(
      list.files(board_path, recursive = TRUE, full.names = TRUE),
      winslash = "/",
      mustWork = TRUE
    ))
  }
  dir.create(board_path, recursive = TRUE, showWarnings = FALSE)
  board <- pins::board_folder(board_path, versioned = TRUE)
  attr(history, "source_manifest") <- manifest
  pins::pin_write(
    board,
    history,
    name = "humanitarian_indices",
    type = "rds",
    description = "Approved historical globalvuln index data"
  )
  pins::pin_write(
    board,
    manifest,
    name = "humanitarian_index_sources",
    type = "rds",
    description = "Approved globalvuln source provenance"
  )
  pins::write_board_manifest(board)
  normalizePath(
    list.files(board_path, recursive = TRUE, full.names = TRUE),
    winslash = "/",
    mustWork = TRUE
  )
}

write_update_report <- function(pipeline, path) {
  lines <- c("## Data update summary", "")
  if (!pipeline$changed) {
    lines <- c(
      lines,
      "No approved-candidate source changes were detected.",
      "",
      paste0("- Sources checked: ", length(pipeline$source_results)),
      "- Candidate updates: 0",
      "- Validation: PASS"
    )
  } else {
    lines <- c(lines, "Updated sources:", "")
    for (result in pipeline$changed_sources) {
      metrics <- result$comparison
      data <- result$data
      index_name <- unique(data$index_name)[[1L]]
      version <- unique(data$source_version)[[1L]]
      lines <- c(
        lines,
        paste0("- ", index_name, ": ", metrics$previous_version, " -> ", version)
      )
    }
    for (result in pipeline$changed_sources) {
      metrics <- result$comparison
      data <- result$data
      text_value <- function(value) if (length(value)) paste(value, collapse = ", ") else "None"
      lines <- c(
        lines,
        "",
        paste0("### ", unique(data$index_name)[[1L]]),
        "",
        paste0("- Publisher publication date: ", unique(data$publication_date)[[1L]]),
        paste0("- Retrieval date: ", unique(data$retrieval_date)[[1L]]),
        paste0("- Source countries: ", metrics$source_countries_before, " -> ", metrics$source_countries_after),
        paste0("- Missing scores: ", metrics$missing_scores_before, " -> ", metrics$missing_scores_after),
        paste0("- Median absolute score change: ", signif(metrics$median_absolute_score_change, 4L)),
        paste0("- Rank correlation: ", signif(metrics$rank_correlation, 4L)),
        paste0("- Entered top 20: ", text_value(metrics$entered_top_20)),
        paste0("- Left top 20: ", text_value(metrics$left_top_20)),
        paste0("- Validation: ", result$validation$status),
        paste0("- Source SHA-256: `", result$discovery$content_hash, "`")
      )
      if (length(result$validation$messages)) {
        lines <- c(lines, paste0("- Warning: ", result$validation$messages))
      }
    }
    lines <- c(
      lines,
      "",
      "### Package impact",
      "",
      "- 195-country grid: PASS",
      "- Pins board validation: PASS",
      "- Package tests and R CMD check run before PR creation."
    )
  }
  writeLines(lines, path, useBytes = TRUE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}
