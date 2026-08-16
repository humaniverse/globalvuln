# Individual humanitarian index datasets

Sixteen consistently structured datasets, one for each published index
in the collection. Each uses the same 195-country master geography so
datasets can be compared or joined directly by `iso3`; rows outside an
index's published coverage contain missing source and score fields.

## Format

Each object is a data frame with 195 rows and the 19 variables
documented in
[humanitarian_indices_long](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_long.md).
Each contains exactly one `index_id` value.

## Source

Publisher details and URLs are in
[humanitarian_index_sources](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_index_sources.md).
Data snapshot: 4 August 2026.

## Details

The included objects are:

- `inform_risk`: INFORM Risk, 2026 v0.7.2.

- `inform_severity`: INFORM Severity, June 2026.

- `underfunded_crisis`: Underfunded Crisis Index, 2025.

- `oecd_fragility`: OECD Multidimensional Fragility, States of Fragility
  2025.

- `worldrisk`: WorldRiskIndex, 2025.

- `nd_gain`: ND-GAIN Country Index, 2026 release using 2024 scores.

- `hdi`: Human Development Index, Human Development Report 2025 using
  2023 scores.

- `mpi`: Global Multidimensional Poverty Index, 2025.

- `ghi`: Global Hunger Index, 2025.

- `ghs`: Global Health Security Index, 2021.

- `wps`: Women, Peace and Security Index, 2025/26.

- `un_mvi`: United Nations Multidimensional Vulnerability Index,
  High-Level Panel results.

- `debt_distress`: International Monetary Fund debt-distress
  classification, 31 March 2026. This classification is not ranked.

- `searo`: Sexual Exploitation and Abuse Risk Overview, 2026 v1.2.

- `disaster_displacement`: IDMC Disaster Displacement Risk Model, GDRM
  2.0. Its rows are retained with missing values because no stable
  downloadable country table was available at the snapshot date.

- `internal_displacement`: IDMC Internal Displacement Index, 2022 values
  published in 2023.

## See also

[humanitarian_indices_country](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_country.md),
[humanitarian_indices_long](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_long.md)

## Examples

``` r
data(inform_risk)

head(inform_risk[!is.na(inform_risk$score),
                 c("country", "score", "rank", "decile")])
#>               country score rank decile
#> 1         Afghanistan   7.8    6      1
#> 2             Albania   3.1  118      7
#> 3             Algeria   4.3   75      4
#> 5              Angola   6.0   27      2
#> 6 Antigua and Barbuda   2.1  165      9
#> 7           Argentina   3.7   94      5
```
