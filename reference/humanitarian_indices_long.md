# Country-index humanitarian vulnerability data

The complete long-form audit table behind
[humanitarian_indices_country](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_country.md).
Every country-index combination is retained, including combinations
outside a publisher's coverage.

## Usage

``` r
humanitarian_indices_long
```

## Format

A data frame with 3,120 rows and 19 variables:

- country:

  Country name from the master geography.

- iso3:

  Three-letter ISO 3166-1 country code.

- region:

  United Nations M49 region.

- subregion:

  United Nations M49 subregion.

- index_id:

  Stable short identifier for the index.

- index_name:

  Human-readable name of the index.

- source_country:

  Country label in the publisher's source; missing when the country was
  not present in that source.

- score:

  Publisher score on its original scale.

- score_label:

  Publisher display label when meaningful, including censored values,
  score ranges, percentages, or classifications.

- reference_year:

  Year or period represented by the observation.

- edition:

  Publisher's edition or release label.

- score_direction:

  Whether a higher or lower publisher score denotes greater
  vulnerability: `higher_worse` or `lower_worse`.

- rankable:

  Whether the index is eligible for ranking.

- eligible_for_counts:

  Whether the rank and decile contribute to the country-level summary
  counts.

- n_scored:

  Number of countries with an exact numeric score for the index.

- rank:

  Rank among scored countries, with 1 denoting most vulnerable; ties
  receive the minimum rank.

- decile:

  Vulnerability decile derived from rank, from 1 (most vulnerable) to 10
  (least vulnerable).

- top_10:

  Whether the observation is in vulnerability decile 1.

- top_20:

  Whether the observation is in vulnerability decile 1 or 2.

## Source

The publishers and editions are recorded in
[humanitarian_index_sources](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_index_sources.md).
Data snapshot: 4 August 2026.

## Details

Rankings and deciles are calculated separately within each index's
published exact numeric coverage. Missing and censored scores are not
ranked. Debt distress is retained as a class and ordinal score but is
intentionally not ranked. No publisher score is rescaled or imputed.

## See also

[humanitarian_indices_country](https://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_country.md),
[individual_indices](https://matthewgthomas.co.uk/globalvuln/reference/individual_indices.md)

## Examples

``` r
data(humanitarian_indices_long)

subset(
  humanitarian_indices_long,
  iso3 == "AFG" & !is.na(rank),
  select = c(index_name, score, rank, decile)
)
#>                                     index_name      score rank decile
#> 1                                  INFORM Risk  7.8000000    6      1
#> 2                              INFORM Severity  9.2000000    4      1
#> 3                     Underfunded Crisis Index 67.2432310   20      8
#> 4              OECD Multidimensional Fragility -4.3952158    3      1
#> 5                               WorldRiskIndex  3.7000000  102      6
#> 6                        ND-GAIN Country Index 33.0241264   11      1
#> 7                      Human Development Index  0.4960000   13      1
#> 8               Multidimensional Poverty Index  0.3603053    9      1
#> 9                          Global Hunger Index 29.0000000   15      2
#> 10                Global Health Security Index 28.8000000   48      3
#> 11             Women, Peace and Security Index  0.2790000    1      1
#> 12     UN Multidimensional Vulnerability Index 54.9000000   58      5
#> 14 Sexual Exploitation and Abuse Risk Overview  7.2211530    2      1
#> 16                 Internal Displacement Index  0.7434270   23      6
```
