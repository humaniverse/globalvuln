# Report cadence-aware source status

Combines approved provenance with publication cadence metadata. An old
but still latest publisher edition is not automatically labelled stale.

## Usage

``` r
source_status(source = c("package", "latest"), as_of = Sys.Date())
```

## Arguments

- source:

  Provenance source: the installed `"package"` snapshot or the approved
  `"latest"` board.

- as_of:

  Date on which status is evaluated. Exposed for reproducible reporting
  and tests.

## Value

A data frame with one row per supported index.

## See also

[`globalvuln_data()`](https://humaniverse.github.io/globalvuln/reference/globalvuln_data.md),
[humanitarian_index_sources](https://humaniverse.github.io/globalvuln/reference/humanitarian_index_sources.md)

## Examples

``` r
source_status(source = "package", as_of = as.Date("2026-08-25"))
#>                 index_id                                  index_name
#> 1            inform_risk                                 INFORM Risk
#> 2        inform_severity                             INFORM Severity
#> 3     underfunded_crisis                    Underfunded Crisis Index
#> 4         oecd_fragility             OECD Multidimensional Fragility
#> 5              worldrisk                              WorldRiskIndex
#> 6                nd_gain                       ND-GAIN Country Index
#> 7                    hdi                     Human Development Index
#> 8                    mpi              Multidimensional Poverty Index
#> 9                    ghi                         Global Hunger Index
#> 10                   ghs                Global Health Security Index
#> 11                   wps             Women, Peace and Security Index
#> 12                un_mvi     UN Multidimensional Vulnerability Index
#> 13         debt_distress                Debt-distress classification
#> 14                 searo Sexual Exploitation and Abuse Risk Overview
#> 15 disaster_displacement            Disaster Displacement Risk Model
#> 16 internal_displacement                 Internal Displacement Index
#>                   source_version publication_date retrieval_date      cadence
#> 1                    2026 v0.7.2       2026-03-31     2026-08-04       annual
#> 2                        2026-06       2026-06-30     2026-08-04      monthly
#> 3                           2025             <NA>     2026-08-04       annual
#> 4       States of Fragility 2025             <NA>     2026-08-04     biennial
#> 5                           2025             <NA>     2026-08-04       annual
#> 6          2026 release+e854c7fe             <NA>     2026-08-25       annual
#> 7  Human Development Report 2025             <NA>     2026-08-04       annual
#> 8                Global MPI 2025             <NA>     2026-08-04       annual
#> 9                  2025+c9420f97             <NA>     2026-08-25       annual
#> 10                          2021             <NA>     2026-08-04    irregular
#> 11                       2025/26             <NA>     2026-08-04     biennial
#> 12      High-Level Panel results             <NA>     2026-08-04    irregular
#> 13                    2026-03-31       2026-03-31     2026-08-04 event_driven
#> 14                     2026 v1.2             <NA>     2026-08-04       annual
#> 15                      GDRM 2.0             <NA>     2026-08-04    irregular
#> 16          IDI 2023 publication             <NA>     2026-08-04    irregular
#>    expected_publication_window             status
#> 1                       8,9,10      expected_soon
#> 2                         <NA>      expected_soon
#> 3                     10,11,12   latest_published
#> 4                         <NA>   latest_published
#> 5                         9,10      expected_soon
#> 6                         <NA>   latest_published
#> 7                         <NA>   latest_published
#> 8                      9,10,11      expected_soon
#> 9                           10   latest_published
#> 10                        <NA> irregular_schedule
#> 11                        <NA>   latest_published
#> 12                        <NA> irregular_schedule
#> 13                        <NA> irregular_schedule
#> 14                        <NA>   latest_published
#> 15                        <NA> irregular_schedule
#> 16                        <NA> irregular_schedule
#>                                               status_reason
#> 1  The source is in its expected annual publication window.
#> 2                The next monthly release is expected soon.
#> 3            This is the latest approved publisher edition.
#> 4           This is the latest approved multi-year edition.
#> 5  The source is in its expected annual publication window.
#> 6            This is the latest approved publisher edition.
#> 7            This is the latest approved publisher edition.
#> 8  The source is in its expected annual publication window.
#> 9            This is the latest approved publisher edition.
#> 10             The publisher has no fixed release schedule.
#> 11          This is the latest approved multi-year edition.
#> 12             The publisher has no fixed release schedule.
#> 13             The publisher has no fixed release schedule.
#> 14           This is the latest approved publisher edition.
#> 15             The publisher has no fixed release schedule.
#> 16             The publisher has no fixed release schedule.
```
