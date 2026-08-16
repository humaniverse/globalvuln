# Collated country-level humanitarian indices

An analysis-ready wide dataset containing score, harmonised
vulnerability rank, and vulnerability decile columns for 16 published
indices. It covers the 193 United Nations member states and the two
United Nations observer states.

## Usage

``` r
humanitarian_indices_country
```

## Format

A data frame with 195 rows and 59 variables:

- country:

  Country name from the master geography.

- iso3:

  Three-letter ISO 3166-1 country code.

- region:

  United Nations M49 region.

- subregion:

  United Nations M49 subregion.

- inform_risk_score:

  INFORM Risk publisher score.

- inform_risk_rank:

  Harmonised vulnerability rank for INFORM Risk.

- inform_risk_decile:

  Harmonised vulnerability decile for INFORM Risk.

- inform_severity_score:

  INFORM Severity publisher score.

- inform_severity_rank:

  Harmonised vulnerability rank for INFORM Severity.

- inform_severity_decile:

  Harmonised vulnerability decile for INFORM Severity.

- underfunded_crisis_score:

  Cumulative percentage of funding requirements met, as reported by the
  Underfunded Crisis Index.

- underfunded_crisis_rank:

  Harmonised vulnerability rank for the Underfunded Crisis Index.

- underfunded_crisis_decile:

  Harmonised vulnerability decile for the Underfunded Crisis Index.

- oecd_fragility_score:

  OECD overall fragility score on the publisher's scale.

- oecd_fragility_rank:

  Harmonised vulnerability rank for OECD Multidimensional Fragility.

- oecd_fragility_decile:

  Harmonised vulnerability decile for OECD Multidimensional Fragility.

- worldrisk_score:

  WorldRiskIndex publisher score.

- worldrisk_rank:

  Harmonised vulnerability rank for WorldRiskIndex.

- worldrisk_decile:

  Harmonised vulnerability decile for WorldRiskIndex.

- nd_gain_score:

  ND-GAIN Country Index publisher score.

- nd_gain_rank:

  Harmonised vulnerability rank for the ND-GAIN Country Index.

- nd_gain_decile:

  Harmonised vulnerability decile for the ND-GAIN Country Index.

- hdi_score:

  Human Development Index publisher score.

- hdi_rank:

  Harmonised vulnerability rank for the Human Development Index.

- hdi_decile:

  Harmonised vulnerability decile for the Human Development Index.

- mpi_score:

  Multidimensional Poverty Index publisher score.

- mpi_rank:

  Harmonised vulnerability rank for the Multidimensional Poverty Index.

- mpi_decile:

  Harmonised vulnerability decile for the Multidimensional Poverty
  Index.

- ghi_score:

  Exact numeric Global Hunger Index publisher score; censored values and
  ranges remain missing.

- ghi_rank:

  Harmonised vulnerability rank for the Global Hunger Index.

- ghi_decile:

  Harmonised vulnerability decile for the Global Hunger Index.

- ghs_score:

  Global Health Security Index publisher score.

- ghs_rank:

  Harmonised vulnerability rank for the Global Health Security Index.

- ghs_decile:

  Harmonised vulnerability decile for the Global Health Security Index.

- wps_score:

  Women, Peace and Security Index publisher score.

- wps_rank:

  Harmonised vulnerability rank for the Women, Peace and Security Index.

- wps_decile:

  Harmonised vulnerability decile for the Women, Peace and Security
  Index.

- un_mvi_score:

  United Nations Multidimensional Vulnerability Index publisher score.

- un_mvi_rank:

  Harmonised vulnerability rank for the United Nations Multidimensional
  Vulnerability Index.

- un_mvi_decile:

  Harmonised vulnerability decile for the United Nations
  Multidimensional Vulnerability Index.

- debt_distress_score:

  Derived debt-distress ordinal score.

- debt_distress_rank:

  Always missing because debt distress is a classification and is not
  ranked.

- debt_distress_decile:

  Always missing because debt distress is a classification and is not
  placed into deciles.

- searo_score:

  Sexual Exploitation and Abuse Risk Overview publisher score.

- searo_rank:

  Harmonised vulnerability rank for the Sexual Exploitation and Abuse
  Risk Overview.

- searo_decile:

  Harmonised vulnerability decile for the Sexual Exploitation and Abuse
  Risk Overview.

- disaster_displacement_score:

  Intended Disaster Displacement Risk Model annual average displacement;
  missing in this snapshot.

- disaster_displacement_rank:

  Harmonised vulnerability rank field; missing in this snapshot.

- disaster_displacement_decile:

  Harmonised vulnerability decile field; missing in this snapshot.

- internal_displacement_score:

  Internal Displacement Index publisher score.

- internal_displacement_rank:

  Harmonised vulnerability rank for the Internal Displacement Index.

- internal_displacement_decile:

  Harmonised vulnerability decile for the Internal Displacement Index.

- ghi_score_label:

  Original Global Hunger Index score label, including censored values
  and ranges that have no invented numeric score.

- mpi_reference_year:

  Country-specific Multidimensional Poverty Index survey year and survey
  type, when published.

- debt_distress_class:

  Published debt-distress classification.

- debt_distress_ordinal:

  Derived debt-distress code: 1 for low, 2 for moderate, 3 for high, and
  4 for in debt distress.

- indices_ranked_count:

  Number of rankable indices with a numeric score for the country.

- top_10_count:

  Number of eligible indices on which the country is in vulnerability
  decile 1.

- top_20_count:

  Number of eligible indices on which the country is in vulnerability
  deciles 1 or 2.

## Source

The publishers and editions are recorded in
[humanitarian_index_sources](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_index_sources.md).
Data snapshot: 4 August 2026.

## Details

The `*_score`, `*_rank`, and `*_decile` fields occur once for each of
the 16 `index_id` values documented in
[individual_indices](https://matthewgthomas.co.uk/globalvuln/reference/individual_indices.md).
Debt distress is a classification and is therefore not ranked or placed
into deciles. The Disaster Displacement Risk Model columns are retained
but contain missing values because the publisher did not provide a
stable downloadable country table at the data snapshot date. All rank
fields use 1 for the most vulnerable scored observation and minimum rank
for ties. All decile fields use 1 for the most vulnerable decile and 10
for the least vulnerable decile.

Deciles are calculated as
`min(10, floor(10 * (rank - 1) / n_scored) + 1)`. Consequently, tied
scores can make a decile contain more than exactly 10 percent of scored
countries. No scores are imputed and no cross-index meta-score is
produced.

## See also

[humanitarian_indices_long](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_long.md),
[individual_indices](https://matthewgthomas.co.uk/globalvuln/reference/individual_indices.md)

## Examples

``` r
data(humanitarian_indices_country)

humanitarian_indices_country[
  humanitarian_indices_country$iso3 == "AFG",
  c("country", "inform_risk_score", "inform_risk_rank", "top_10_count")
]
#>       country inform_risk_score inform_risk_rank top_10_count
#> 1 Afghanistan               7.8                6            8
```
