pipeline_ancestors <- character()
pipeline_cursor <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
for (i in 0:5) {
  pipeline_ancestors <- c(pipeline_ancestors, pipeline_cursor)
  pipeline_cursor <- dirname(pipeline_cursor)
}
pipeline_root_candidates <- c(
  pipeline_ancestors,
  file.path(pipeline_ancestors, "00_pkg_src", "globalvuln"),
  normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = FALSE)
)
pipeline_root_candidates <- unique(pipeline_root_candidates)
has_pipeline <- vapply(
  pipeline_root_candidates,
  function(path) dir.exists(file.path(path, "data-raw", "R")),
  logical(1)
)
pipeline_available <- any(has_pipeline)
if (pipeline_available) {
  pipeline_root <- pipeline_root_candidates[which(has_pipeline)[[1L]]]
  pipeline_path <- function(...) file.path(pipeline_root, ...)

  pipeline_files <- list.files(
    pipeline_path("data-raw", "R"),
    pattern = "[.]R$",
    full.names = TRUE
  )
  invisible(lapply(pipeline_files, sys.source, envir = environment()))
} else {
  pipeline_path <- function(...) NA_character_
}
