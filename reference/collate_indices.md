# Collate selected humanitarian vulnerability indices

Combine any selection of the package's individual index datasets in
either wide or long form. All 195 United Nations member and observer
states are retained, including countries outside an index's published
coverage.

## Usage

``` r
collate_indices(indices, format = c("wide", "long"))
```

## Arguments

- indices:

  A non-empty character vector of index identifiers. Available
  identifiers are `inform_risk`, `inform_severity`,
  `underfunded_crisis`, `oecd_fragility`, `worldrisk`, `nd_gain`, `hdi`,
  `mpi`, `ghi`, `ghs`, `wps`, `un_mvi`, `debt_distress`, `searo`,
  `disaster_displacement`, and `internal_displacement`. Identifiers must
  be unique and their supplied order is preserved.

- format:

  Output layout: `"wide"` (the default) or `"long"`.

## Value

A data frame. Wide output has one row per country, four geography
columns, `*_score`, `*_rank`, and `*_decile` columns for each selected
index, applicable index-specific fields, and five country summary
columns. Long output has one row per country-index combination, the 19
fields documented in
[individual_indices](https://humaniverse.github.io/globalvuln/reference/individual_indices.md),
and the same five summary columns.

## Details

`top_10` and `top_20` identify ranks less than or equal to 10 and 20,
respectively; they do not refer to deciles. Because ties receive the
minimum rank, more than 10 or 20 countries can meet a threshold for an
index.

The summary fields are:

- `indices_ranked_count`: selected eligible indices for which the
  country has a non-missing rank.

- `top_10_count` and `top_20_count`: the number of those ranks meeting
  each threshold.

- `top_10_proportion` and `top_20_proportion`: each count divided by
  `indices_ranked_count`.

A country with no available eligible rank has zero counts and missing
proportions. Missing scores are not treated as ranks outside the
thresholds. In long output, country summaries are repeated on every
selected index row.

Wide output includes `ghi_score_label`, `mpi_reference_year`,
`debt_distress_class`, and `debt_distress_ordinal` when their
corresponding indices are selected.

## See also

[individual_indices](https://humaniverse.github.io/globalvuln/reference/individual_indices.md),
[humanitarian_index_sources](https://humaniverse.github.io/globalvuln/reference/humanitarian_index_sources.md)

## Examples

``` r
selected_wide <- collate_indices(
  c("inform_risk", "hdi", "mpi")
)
selected_wide[
  selected_wide$iso3 == "AFG",
  c("country", "inform_risk_rank", "top_10_proportion")
]
#>       country inform_risk_rank top_10_proportion
#> 1 Afghanistan                6         0.6666667

selected_long <- collate_indices(
  c("inform_risk", "hdi", "mpi"),
  format = "long"
)
subset(
  selected_long,
  iso3 == "AFG",
  select = c(index_name, score, rank, top_10)
)
#>                       index_name     score rank top_10
#> 1                    INFORM Risk 7.8000000    6   TRUE
#> 2        Human Development Index 0.4960000   13  FALSE
#> 3 Multidimensional Poverty Index 0.3603053    9   TRUE
```
