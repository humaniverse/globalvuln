#' Retrieve bundled or latest approved globalvuln data
#'
#' `globalvuln_data()` makes data freshness explicit. Package data are the
#' immutable snapshot installed with `globalvuln`; latest data are read from
#' the approved, versioned static board published with the package website.
#'
#' @param source Data source. `"latest"` reads the approved online board and
#'   `"package"` reads the installed package snapshot offline.
#' @param version Optional version of the `humanitarian_indices` pin. Versions
#'   are only supported for `source = "latest"`.
#' @param indices Optional character vector of index identifiers. The default
#'   selects all supported indices.
#' @param format Output layout: `"long"` (the default) or `"wide"`.
#'
#' @return A data frame with provenance in the `globalvuln_source`,
#'   `globalvuln_version`, and `globalvuln_manifest` attributes.
#' @export
#' @seealso [collate_indices()], [source_status()]
#' @examples
#' package_data <- globalvuln_data(
#'   source = "package",
#'   indices = c("inform_risk", "hdi")
#' )
globalvuln_data <- function(
    source = c("latest", "package"),
    version = NULL,
    indices = NULL,
    format = c("long", "wide")) {
  source <- match.arg(source)
  format <- match.arg(format)
  if (is.null(indices)) {
    indices <- .index_ids
  } else {
    indices <- validate_indices(indices)
  }

  if (identical(source, "package")) {
    if (!is.null(version)) {
      stop(
        "`version` can only be used with `source = \"latest\"`.",
        call. = FALSE
      )
    }
    index_data <- load_index_data(indices)
    long <- do.call(rbind, index_data)
    rownames(long) <- NULL
    manifest <- load_approved_source_manifest()
    if (is.null(manifest)) {
      manifest <- load_package_manifest()
    }
    data_version <- as.character(utils::packageVersion("globalvuln"))
  } else {
    board_url <- getOption(
      "globalvuln.board_url",
      "https://humaniverse.github.io/globalvuln/data/"
    )
    board <- tryCatch(
      if (dir.exists(board_url)) {
        pins::board_folder(board_url, versioned = TRUE)
      } else {
        pins::board_url(board_url)
      },
      error = function(error) latest_data_error(error)
    )
    long <- tryCatch(
      pins::pin_read(
        board,
        name = "humanitarian_indices",
        version = version
      ),
      error = function(error) latest_data_error(error)
    )
    if (!is.data.frame(long)) {
      stop("The approved globalvuln data pin is not a data frame.", call. = FALSE)
    }
    manifest <- attr(long, "source_manifest", exact = TRUE)
    if (is.null(manifest)) {
      manifest <- tryCatch(
        pins::pin_read(board, "humanitarian_index_sources"),
        error = function(error) latest_data_error(error)
      )
    }
    long <- latest_history_rows(long, manifest)
    long <- long[long$index_id %in% indices, , drop = FALSE]
    data_version <- if (is.null(version)) "latest" else version
  }

  long <- order_long_data(long, indices)
  index_data <- unname(split(
    long,
    factor(long$index_id, levels = indices),
    drop = TRUE
  ))

  if (identical(format, "long")) {
    result <- add_rank_summaries(long, indices)
  } else {
    included <- long$eligible_for_counts %in% TRUE & !is.na(long$rank)
    long$top_10 <- rep(NA, nrow(long))
    long$top_20 <- rep(NA, nrow(long))
    long$top_10[included] <- long$rank[included] <= 10L
    long$top_20[included] <- long$rank[included] <= 20L
    country_order <- index_data[[1L]]$iso3
    summaries <- summarise_country_ranks(long, country_order)
    index_data <- unname(split(
      long,
      factor(long$index_id, levels = indices),
      drop = TRUE
    ))
    result <- build_wide_indices(index_data, indices, summaries)
  }

  attr(result, "globalvuln_source") <- source
  attr(result, "globalvuln_version") <- data_version
  attr(result, "globalvuln_manifest") <- manifest
  result
}

latest_data_error <- function(error) {
  stop(
    "Unable to retrieve the latest approved globalvuln data. ",
    "Use `source = \"package\"` for the bundled snapshot.\n",
    "Underlying error: ", conditionMessage(error),
    call. = FALSE
  )
}
