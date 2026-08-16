#' Collated country-level humanitarian indices
#'
#' An analysis-ready wide dataset containing score, harmonised vulnerability
#' rank, and vulnerability decile columns for 16 published indices. It covers
#' the 193 United Nations member states and the two United Nations observer
#' states.
#'
#' @format A data frame with 195 rows and 59 variables:
#' \describe{
#'   \item{country}{Country name from the master geography.}
#'   \item{iso3}{Three-letter ISO 3166-1 country code.}
#'   \item{region}{United Nations M49 region.}
#'   \item{subregion}{United Nations M49 subregion.}
#'   \item{inform_risk_score}{INFORM Risk publisher score.}
#'   \item{inform_risk_rank}{Harmonised vulnerability rank for INFORM Risk.}
#'   \item{inform_risk_decile}{Harmonised vulnerability decile for INFORM Risk.}
#'   \item{inform_severity_score}{INFORM Severity publisher score.}
#'   \item{inform_severity_rank}{Harmonised vulnerability rank for INFORM Severity.}
#'   \item{inform_severity_decile}{Harmonised vulnerability decile for INFORM Severity.}
#'   \item{underfunded_crisis_score}{Cumulative percentage of funding requirements met, as reported by the Underfunded Crisis Index.}
#'   \item{underfunded_crisis_rank}{Harmonised vulnerability rank for the Underfunded Crisis Index.}
#'   \item{underfunded_crisis_decile}{Harmonised vulnerability decile for the Underfunded Crisis Index.}
#'   \item{oecd_fragility_score}{OECD overall fragility score on the publisher's scale.}
#'   \item{oecd_fragility_rank}{Harmonised vulnerability rank for OECD Multidimensional Fragility.}
#'   \item{oecd_fragility_decile}{Harmonised vulnerability decile for OECD Multidimensional Fragility.}
#'   \item{worldrisk_score}{WorldRiskIndex publisher score.}
#'   \item{worldrisk_rank}{Harmonised vulnerability rank for WorldRiskIndex.}
#'   \item{worldrisk_decile}{Harmonised vulnerability decile for WorldRiskIndex.}
#'   \item{nd_gain_score}{ND-GAIN Country Index publisher score.}
#'   \item{nd_gain_rank}{Harmonised vulnerability rank for the ND-GAIN Country Index.}
#'   \item{nd_gain_decile}{Harmonised vulnerability decile for the ND-GAIN Country Index.}
#'   \item{hdi_score}{Human Development Index publisher score.}
#'   \item{hdi_rank}{Harmonised vulnerability rank for the Human Development Index.}
#'   \item{hdi_decile}{Harmonised vulnerability decile for the Human Development Index.}
#'   \item{mpi_score}{Multidimensional Poverty Index publisher score.}
#'   \item{mpi_rank}{Harmonised vulnerability rank for the Multidimensional Poverty Index.}
#'   \item{mpi_decile}{Harmonised vulnerability decile for the Multidimensional Poverty Index.}
#'   \item{ghi_score}{Exact numeric Global Hunger Index publisher score; censored values and ranges remain missing.}
#'   \item{ghi_rank}{Harmonised vulnerability rank for the Global Hunger Index.}
#'   \item{ghi_decile}{Harmonised vulnerability decile for the Global Hunger Index.}
#'   \item{ghs_score}{Global Health Security Index publisher score.}
#'   \item{ghs_rank}{Harmonised vulnerability rank for the Global Health Security Index.}
#'   \item{ghs_decile}{Harmonised vulnerability decile for the Global Health Security Index.}
#'   \item{wps_score}{Women, Peace and Security Index publisher score.}
#'   \item{wps_rank}{Harmonised vulnerability rank for the Women, Peace and Security Index.}
#'   \item{wps_decile}{Harmonised vulnerability decile for the Women, Peace and Security Index.}
#'   \item{un_mvi_score}{United Nations Multidimensional Vulnerability Index publisher score.}
#'   \item{un_mvi_rank}{Harmonised vulnerability rank for the United Nations Multidimensional Vulnerability Index.}
#'   \item{un_mvi_decile}{Harmonised vulnerability decile for the United Nations Multidimensional Vulnerability Index.}
#'   \item{debt_distress_score}{Derived debt-distress ordinal score.}
#'   \item{debt_distress_rank}{Always missing because debt distress is a classification and is not ranked.}
#'   \item{debt_distress_decile}{Always missing because debt distress is a classification and is not placed into deciles.}
#'   \item{searo_score}{Sexual Exploitation and Abuse Risk Overview publisher score.}
#'   \item{searo_rank}{Harmonised vulnerability rank for the Sexual Exploitation and Abuse Risk Overview.}
#'   \item{searo_decile}{Harmonised vulnerability decile for the Sexual Exploitation and Abuse Risk Overview.}
#'   \item{disaster_displacement_score}{Intended Disaster Displacement Risk Model annual average displacement; missing in this snapshot.}
#'   \item{disaster_displacement_rank}{Harmonised vulnerability rank field; missing in this snapshot.}
#'   \item{disaster_displacement_decile}{Harmonised vulnerability decile field; missing in this snapshot.}
#'   \item{internal_displacement_score}{Internal Displacement Index publisher score.}
#'   \item{internal_displacement_rank}{Harmonised vulnerability rank for the Internal Displacement Index.}
#'   \item{internal_displacement_decile}{Harmonised vulnerability decile for the Internal Displacement Index.}
#'   \item{ghi_score_label}{Original Global Hunger Index score label, including
#'   censored values and ranges that have no invented numeric score.}
#'   \item{mpi_reference_year}{Country-specific Multidimensional Poverty Index
#'   survey year and survey type, when published.}
#'   \item{debt_distress_class}{Published debt-distress classification.}
#'   \item{debt_distress_ordinal}{Derived debt-distress code: 1 for low, 2 for
#'   moderate, 3 for high, and 4 for in debt distress.}
#'   \item{indices_ranked_count}{Number of rankable indices with a numeric score
#'   for the country.}
#'   \item{top_10_count}{Number of eligible indices on which the country is in
#'   vulnerability decile 1.}
#'   \item{top_20_count}{Number of eligible indices on which the country is in
#'   vulnerability deciles 1 or 2.}
#' }
#'
#' @details
#' The `*_score`, `*_rank`, and `*_decile` fields occur once for each of the 16
#' `index_id` values documented in [individual_indices]. Debt distress is a
#' classification and is therefore not ranked or placed into deciles. The
#' Disaster Displacement Risk Model columns are retained but contain missing
#' values because the publisher did not provide a stable downloadable country
#' table at the data snapshot date.
#' All rank fields use 1 for the most vulnerable scored observation and minimum
#' rank for ties. All decile fields use 1 for the most vulnerable decile and 10
#' for the least vulnerable decile.
#'
#' Deciles are calculated as
#' `min(10, floor(10 * (rank - 1) / n_scored) + 1)`. Consequently, tied scores
#' can make a decile contain more than exactly 10 percent of scored countries.
#' No scores are imputed and no cross-index meta-score is produced.
#'
#' @source The publishers and editions are recorded in
#' [humanitarian_index_sources]. Data snapshot: 4 August 2026.
#' @seealso [humanitarian_indices_long], [individual_indices]
#' @examples
#' data(humanitarian_indices_country)
#'
#' humanitarian_indices_country[
#'   humanitarian_indices_country$iso3 == "AFG",
#'   c("country", "inform_risk_score", "inform_risk_rank", "top_10_count")
#' ]
"humanitarian_indices_country"

#' Country-index humanitarian vulnerability data
#'
#' The complete long-form audit table behind [humanitarian_indices_country].
#' Every country-index combination is retained, including combinations outside
#' a publisher's coverage.
#'
#' @format A data frame with 3,120 rows and 19 variables:
#' \describe{
#'   \item{country}{Country name from the master geography.}
#'   \item{iso3}{Three-letter ISO 3166-1 country code.}
#'   \item{region}{United Nations M49 region.}
#'   \item{subregion}{United Nations M49 subregion.}
#'   \item{index_id}{Stable short identifier for the index.}
#'   \item{index_name}{Human-readable name of the index.}
#'   \item{source_country}{Country label in the publisher's source; missing
#'   when the country was not present in that source.}
#'   \item{score}{Publisher score on its original scale.}
#'   \item{score_label}{Publisher display label when meaningful, including
#'   censored values, score ranges, percentages, or classifications.}
#'   \item{reference_year}{Year or period represented by the observation.}
#'   \item{edition}{Publisher's edition or release label.}
#'   \item{score_direction}{Whether a higher or lower publisher score denotes
#'   greater vulnerability: `higher_worse` or `lower_worse`.}
#'   \item{rankable}{Whether the index is eligible for ranking.}
#'   \item{eligible_for_counts}{Whether the rank and decile contribute to the
#'   country-level summary counts.}
#'   \item{n_scored}{Number of countries with an exact numeric score for the
#'   index.}
#'   \item{rank}{Rank among scored countries, with 1 denoting most vulnerable;
#'   ties receive the minimum rank.}
#'   \item{decile}{Vulnerability decile derived from rank, from 1 (most
#'   vulnerable) to 10 (least vulnerable).}
#'   \item{top_10}{Whether the observation is in vulnerability decile 1.}
#'   \item{top_20}{Whether the observation is in vulnerability decile 1 or 2.}
#' }
#'
#' @details
#' Rankings and deciles are calculated separately within each index's published
#' exact numeric coverage. Missing and censored scores are not ranked. Debt
#' distress is retained as a class and ordinal score but is intentionally not
#' ranked. No publisher score is rescaled or imputed.
#'
#' @source The publishers and editions are recorded in
#' [humanitarian_index_sources]. Data snapshot: 4 August 2026.
#' @seealso [humanitarian_indices_country], [individual_indices]
#' @examples
#' data(humanitarian_indices_long)
#'
#' subset(
#'   humanitarian_indices_long,
#'   iso3 == "AFG" & !is.na(rank),
#'   select = c(index_name, score, rank, decile)
#' )
"humanitarian_indices_long"

#' Sources and provenance for the humanitarian indices
#'
#' Publisher, edition, retrieval, licensing, checksum, and coverage metadata
#' for every index source and the United Nations M49 geography source used to
#' create the package datasets.
#'
#' @format A data frame with 17 rows and 17 variables:
#' \describe{
#'   \item{source_id}{Stable source identifier. For index sources this equals
#'   `index_id`; `un_m49` identifies the geography source.}
#'   \item{source_name}{Human-readable source or index name.}
#'   \item{edition}{Publisher edition or release.}
#'   \item{reference_year}{Year or period represented by the source.}
#'   \item{source_url}{Publisher landing page.}
#'   \item{download_url}{URL used to retrieve the source snapshot, if any.}
#'   \item{local_file}{Path used by the source processing pipeline.}
#'   \item{retrieval_date}{Date on which the source snapshot was retrieved.}
#'   \item{sha256}{SHA-256 checksum of the source snapshot.}
#'   \item{file_bytes}{Size of the source snapshot in bytes.}
#'   \item{source_status}{Availability or manual-input status.}
#'   \item{n_numeric_scores}{Number of exact numeric scores parsed.}
#'   \item{n_labelled_records}{Number of publisher labels retained.}
#'   \item{n_ranked}{Number of observations included in ranking.}
#'   \item{coverage_ok}{Whether observed coverage passed its configured check.}
#'   \item{license_notes}{Publisher attribution or reuse note.}
#'   \item{source_notes}{Processing or interpretation note.}
#' }
#'
#' @details
#' Raw source files remain the property of their publishers and are governed by
#' their respective terms. Users should cite the relevant publisher when using
#' an index. The `local_file` paths describe the reproducible source pipeline
#' and are not paths within an installed `globalvuln` package.
#'
#' @source Publisher pages in the `source_url` column. Metadata snapshot:
#' 4 August 2026.
#' @seealso [humanitarian_indices_country], [humanitarian_indices_long]
#' @examples
#' data(humanitarian_index_sources)
#'
#' humanitarian_index_sources[
#'   humanitarian_index_sources$source_id == "inform_risk",
#'   c("source_name", "edition", "source_url")
#' ]
"humanitarian_index_sources"

#' Individual humanitarian index datasets
#'
#' Sixteen consistently structured datasets, one for each published index in
#' the collection. Each uses the same 195-country master geography so datasets
#' can be compared or joined directly by `iso3`; rows outside an index's
#' published coverage contain missing source and score fields.
#'
#' @name individual_indices
#' @aliases inform_risk inform_severity underfunded_crisis oecd_fragility worldrisk nd_gain hdi mpi ghi ghs wps un_mvi debt_distress searo disaster_displacement internal_displacement
#'
#' @format Each object is a data frame with 195 rows and the 19 variables
#' documented in [humanitarian_indices_long]. Each contains exactly one
#' `index_id` value.
#'
#' @details
#' The included objects are:
#'
#' * `inform_risk`: INFORM Risk, 2026 v0.7.2.
#' * `inform_severity`: INFORM Severity, June 2026.
#' * `underfunded_crisis`: Underfunded Crisis Index, 2025.
#' * `oecd_fragility`: OECD Multidimensional Fragility, States of Fragility
#'   2025.
#' * `worldrisk`: WorldRiskIndex, 2025.
#' * `nd_gain`: ND-GAIN Country Index, 2026 release using 2024 scores.
#' * `hdi`: Human Development Index, Human Development Report 2025 using 2023
#'   scores.
#' * `mpi`: Global Multidimensional Poverty Index, 2025.
#' * `ghi`: Global Hunger Index, 2025.
#' * `ghs`: Global Health Security Index, 2021.
#' * `wps`: Women, Peace and Security Index, 2025/26.
#' * `un_mvi`: United Nations Multidimensional Vulnerability Index,
#'   High-Level Panel results.
#' * `debt_distress`: International Monetary Fund debt-distress
#'   classification, 31 March 2026. This classification is not ranked.
#' * `searo`: Sexual Exploitation and Abuse Risk Overview, 2026 v1.2.
#' * `disaster_displacement`: IDMC Disaster Displacement Risk Model, GDRM 2.0.
#'   Its rows are retained with missing values because no stable downloadable
#'   country table was available at the snapshot date.
#' * `internal_displacement`: IDMC Internal Displacement Index, 2022 values
#'   published in 2023.
#'
#' @source Publisher details and URLs are in [humanitarian_index_sources]. Data
#' snapshot: 4 August 2026.
#' @seealso [humanitarian_indices_country], [humanitarian_indices_long]
#' @examples
#' data(inform_risk)
#'
#' head(inform_risk[!is.na(inform_risk$score),
#'                  c("country", "score", "rank", "decile")])
NULL
