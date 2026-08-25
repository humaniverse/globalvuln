args <- commandArgs(trailingOnly = TRUE)
board_path <- if (length(args)) args[[1L]] else "data-published"

if (!dir.exists(board_path)) {
  stop("Pins board directory does not exist: ", board_path, call. = FALSE)
}

board <- pins::board_folder(board_path, versioned = TRUE)
expected <- c("humanitarian_indices", "humanitarian_index_sources")
available <- pins::pin_list(board)
if (is.data.frame(available)) {
  available <- available$name
}
missing <- setdiff(expected, available)
if (length(missing)) {
  stop("Pins board is missing: ", paste(missing, collapse = ", "), call. = FALSE)
}

history <- pins::pin_read(board, "humanitarian_indices")
manifest <- pins::pin_read(board, "humanitarian_index_sources")
if (!is.data.frame(history) || !is.data.frame(manifest)) {
  stop("Expected pins must both contain data frames.", call. = FALSE)
}
if (!all(c("index_id", "source_version", "iso3") %in% names(history))) {
  stop("Historical data pin violates the canonical key contract.", call. = FALSE)
}
if (anyDuplicated(history[c("index_id", "source_version", "iso3")])) {
  stop("Historical data pin contains duplicate canonical keys.", call. = FALSE)
}
if (!setequal(unique(history$index_id), manifest$index_id)) {
  stop("Pins data and manifest cover different source IDs.", call. = FALSE)
}

cat("Pins board validation: PASS\n")
