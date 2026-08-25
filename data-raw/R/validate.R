validate_source_candidate <- function(data, discovery) {
  common <- validate_canonical_data(data, discovery)
  adapter <- discovery$registry_entry$adapter[[1L]]
  specific <- get(paste0("validate_", adapter), mode = "function")(
    data,
    discovery
  )
  combine_validation(common, specific)
}

validate_canonical_data <- function(data, discovery) {
  messages <- character()
  status <- "PASS"
  fail <- function(message) {
    messages <<- c(messages, message)
    status <<- "FAIL"
  }
  if (!all(canonical_columns %in% names(data))) {
    fail(paste(
      "Missing canonical columns:",
      paste(setdiff(canonical_columns, names(data)), collapse = ", ")
    ))
    return(validation_result(status, messages))
  }
  if (nrow(data) != 195L || length(unique(data$iso3)) != 195L) {
    fail("Candidate does not preserve the 195-country grid.")
  }
  if (anyNA(data$iso3) || any(!grepl("^[A-Z]{3}$", data$iso3))) {
    fail("Candidate contains an invalid ISO3 code.")
  }
  if (anyDuplicated(data[c("index_id", "source_version", "iso3")])) {
    fail("Candidate contains duplicate canonical keys.")
  }
  if (anyNA(data$source_version) || any(!nzchar(data$source_version))) {
    fail("Candidate source version is missing.")
  }
  if (all(is.na(data$score))) {
    fail("Candidate score column is entirely missing.")
  }
  if (any(!is.na(data$rank) & data$rank < 1L)) {
    fail("Candidate contains an invalid rank.")
  }
  if (any(!is.na(data$decile) & !data$decile %in% 1:10)) {
    fail("Candidate contains an invalid decile.")
  }
  validation_result(status, messages)
}

assert_pipeline_valid <- function(source_results) {
  failed <- vapply(
    source_results,
    function(result) identical(result$validation$status, "FAIL"),
    logical(1)
  )
  if (any(failed)) {
    details <- vapply(source_results[failed], function(result) {
      paste0(
        result$discovery$index_id,
        ": ",
        paste(result$validation$messages, collapse = "; ")
      )
    }, character(1))
    stop(
      "Pipeline validation failed; no candidate data were published.\n- ",
      paste(details, collapse = "\n- "),
      call. = FALSE
    )
  }
  invisible(source_results)
}
