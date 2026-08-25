#' Collate selected humanitarian vulnerability indices
#'
#' Combine any selection of the package's individual index datasets in either
#' wide or long form. All 195 United Nations member and observer states are
#' retained, including countries outside an index's published coverage.
#'
#' @param indices A non-empty character vector of index identifiers. Available
#'   identifiers are `inform_risk`, `inform_severity`, `underfunded_crisis`,
#'   `oecd_fragility`, `worldrisk`, `nd_gain`, `hdi`, `mpi`, `ghi`, `ghs`,
#'   `wps`, `un_mvi`, `debt_distress`, `searo`, `disaster_displacement`, and
#'   `internal_displacement`. Identifiers must be unique and their supplied
#'   order is preserved.
#' @param format Output layout: `"wide"` (the default) or `"long"`.
#'
#' @return A data frame. Wide output has one row per country, four geography
#'   columns, `*_score`, `*_rank`, and `*_decile` columns for each selected
#'   index, applicable index-specific fields, and five country summary columns.
#'   Long output has one row per country-index combination, the 19 fields
#'   documented in [individual_indices], and the same five summary columns.
#'
#' @details
#' `top_10` and `top_20` identify ranks less than or equal to 10 and 20,
#' respectively; they do not refer to deciles. Because ties receive the minimum
#' rank, more than 10 or 20 countries can meet a threshold for an index.
#'
#' The summary fields are:
#'
#' * `indices_ranked_count`: selected eligible indices for which the country
#'   has a non-missing rank.
#' * `top_10_count` and `top_20_count`: the number of those ranks meeting each
#'   threshold.
#' * `top_10_proportion` and `top_20_proportion`: each count divided by
#'   `indices_ranked_count`.
#'
#' A country with no available eligible rank has zero counts and missing
#' proportions. Missing scores are not treated as ranks outside the thresholds.
#' In long output, country summaries are repeated on every selected index row.
#'
#' Wide output includes `ghi_score_label`, `mpi_reference_year`,
#' `debt_distress_class`, and `debt_distress_ordinal` when their corresponding
#' indices are selected.
#'
#' @seealso [individual_indices], [humanitarian_index_sources]
#' @export
#' @examples
#' selected_wide <- collate_indices(
#'   c("inform_risk", "hdi", "mpi")
#' )
#' selected_wide[
#'   selected_wide$iso3 == "AFG",
#'   c("country", "inform_risk_rank", "top_10_proportion")
#' ]
#'
#' selected_long <- collate_indices(
#'   c("inform_risk", "hdi", "mpi"),
#'   format = "long"
#' )
#' subset(
#'   selected_long,
#'   iso3 == "AFG",
#'   select = c(index_name, score, rank, top_10)
#' )
collate_indices <- function(indices, format = c("wide", "long")) {
  indices <- validate_indices(indices)
  format <- match.arg(format)

  index_data <- load_index_data(indices)
  country_order <- index_data[[1L]]$iso3
  long <- do.call(rbind, index_data)
  rownames(long) <- NULL

  long <- long[
    order(
      match(long$iso3, country_order),
      match(long$index_id, indices)
    ),
    ,
    drop = FALSE
  ]
  rownames(long) <- NULL

  included <- long$eligible_for_counts %in% TRUE & !is.na(long$rank)
  long$top_10 <- rep(NA, nrow(long))
  long$top_20 <- rep(NA, nrow(long))
  long$top_10[included] <- long$rank[included] <= 10L
  long$top_20[included] <- long$rank[included] <= 20L

  summaries <- summarise_country_ranks(long, country_order)

  if (identical(format, "long")) {
    summary_rows <- summaries[
      match(long$iso3, summaries$iso3),
      setdiff(names(summaries), "iso3"),
      drop = FALSE
    ]
    result <- cbind(long, summary_rows)
    rownames(result) <- NULL
    return(result)
  }

  build_wide_indices(index_data, indices, summaries)
}

validate_indices <- function(indices) {
  if (missing(indices)) {
    stop("`indices` is required and must contain at least one index identifier.",
         call. = FALSE)
  }
  if (!is.character(indices)) {
    stop("`indices` must be a character vector of index identifiers.",
         call. = FALSE)
  }
  if (!length(indices)) {
    stop("`indices` must contain at least one index identifier.",
         call. = FALSE)
  }
  if (anyNA(indices) || any(!nzchar(indices))) {
    stop("`indices` cannot contain missing or empty values.", call. = FALSE)
  }
  if (anyDuplicated(indices)) {
    duplicates <- unique(indices[duplicated(indices)])
    stop(
      "`indices` must be unique; duplicated: ",
      paste(duplicates, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unknown <- setdiff(indices, .index_ids)
  if (length(unknown)) {
    stop(
      "Unknown index identifier", if (length(unknown) > 1L) "s" else "",
      ": ", paste(unknown, collapse = ", "), ". Available identifiers are: ",
      paste(.index_ids, collapse = ", "), ".",
      call. = FALSE
    )
  }

  indices
}

load_index_data <- function(indices) {
  data_environment <- new.env(parent = emptyenv())
  utils::data(
    list = indices,
    package = "globalvuln",
    envir = data_environment
  )

  loaded <- vapply(
    indices,
    exists,
    logical(1),
    envir = data_environment,
    inherits = FALSE
  )
  if (!all(loaded)) {
    stop(
      "Unable to load package data for: ",
      paste(indices[!loaded], collapse = ", "),
      ". Reinstall `globalvuln` and try again.",
      call. = FALSE
    )
  }

  unname(mget(indices, envir = data_environment, inherits = FALSE))
}

summarise_country_ranks <- function(long, country_order) {
  indices_ranked_count <- vapply(country_order, function(country_id) {
    rows <- long$iso3 == country_id
    sum(long$eligible_for_counts[rows] %in% TRUE & !is.na(long$rank[rows]))
  }, integer(1))
  top_10_count <- vapply(country_order, function(country_id) {
    sum(long$top_10[long$iso3 == country_id] %in% TRUE)
  }, integer(1))
  top_20_count <- vapply(country_order, function(country_id) {
    sum(long$top_20[long$iso3 == country_id] %in% TRUE)
  }, integer(1))

  data.frame(
    iso3 = country_order,
    indices_ranked_count = indices_ranked_count,
    top_10_count = top_10_count,
    top_10_proportion = ifelse(
      indices_ranked_count == 0L,
      NA_real_,
      top_10_count / indices_ranked_count
    ),
    top_20_count = top_20_count,
    top_20_proportion = ifelse(
      indices_ranked_count == 0L,
      NA_real_,
      top_20_count / indices_ranked_count
    ),
    row.names = NULL,
    check.names = FALSE
  )
}

build_wide_indices <- function(index_data, indices, summaries) {
  geography <- index_data[[1L]][
    ,
    c("country", "iso3", "region", "subregion"),
    drop = FALSE
  ]
  result <- geography

  for (i in seq_along(indices)) {
    index_id <- indices[[i]]
    rows <- index_data[[i]][
      match(geography$iso3, index_data[[i]]$iso3),
      ,
      drop = FALSE
    ]
    for (field in c("score", "rank", "decile")) {
      result[[paste0(index_id, "_", field)]] <- rows[[field]]
    }
  }

  if ("ghi" %in% indices) {
    rows <- index_data[[match("ghi", indices)]]
    result$ghi_score_label <- rows$score_label[match(geography$iso3, rows$iso3)]
  }
  if ("mpi" %in% indices) {
    rows <- index_data[[match("mpi", indices)]]
    result$mpi_reference_year <- rows$reference_year[
      match(geography$iso3, rows$iso3)
    ]
  }
  if ("debt_distress" %in% indices) {
    rows <- index_data[[match("debt_distress", indices)]]
    positions <- match(geography$iso3, rows$iso3)
    result$debt_distress_class <- rows$score_label[positions]
    result$debt_distress_ordinal <- rows$score[positions]
  }

  summary_rows <- summaries[
    match(geography$iso3, summaries$iso3),
    setdiff(names(summaries), "iso3"),
    drop = FALSE
  ]
  result <- cbind(result, summary_rows)
  rownames(result) <- NULL
  result
}
