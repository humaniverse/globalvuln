# Rebuild approved package data through the repository-owned pipeline.
# Run this script from the globalvuln package root.

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Install the `targets` package before rebuilding data.", call. = FALSE)
}

targets::tar_make(names = "published_files")
