#' globalvuln: Global Humanitarian Vulnerability Indices
#'
#' Country-level data from 16 published global vulnerability, fragility,
#' development, hunger, health, gender, debt, safeguarding, and displacement
#' indices.
#'
#' @details
#' The package provides complementary interfaces for reproducible and current
#' analysis:
#'
#' * [collate_indices()] combines a user-selected set of indices in wide or
#'   long form.
#' * The 16 datasets documented in [individual_indices] expose one index at a
#'   time on the same 195-country geography.
#' * [humanitarian_index_sources] records source and provenance metadata.
#' * [globalvuln_data()] explicitly selects the installed snapshot or latest
#'   approved online data.
#' * [source_status()] reports cadence-aware source status.
#'
#' Publisher scores retain their original scales. Computed ranks and deciles
#' have a common direction: rank 1 and decile 1 always identify the most
#' vulnerable observations within an index's published numeric coverage.
#' Top-10 and top-20 summaries use ranks, not deciles.
#'
#' @keywords internal
"_PACKAGE"
