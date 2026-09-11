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
#>                 index_id                                             index_name
#> 1                clif_vi Climate Finance Vulnerability Index (2050 pessimistic)
#> 2            inform_risk                                            INFORM Risk
#> 3        inform_severity                                        INFORM Severity
#> 4     underfunded_crisis                               Underfunded Crisis Index
#> 5         oecd_fragility                        OECD Multidimensional Fragility
#> 6              worldrisk                                         WorldRiskIndex
#> 7                nd_gain                                  ND-GAIN Country Index
#> 8                    hdi                                Human Development Index
#> 9                    mpi                         Multidimensional Poverty Index
#> 10                   ghi                                    Global Hunger Index
#> 11                   ghs                           Global Health Security Index
#> 12                   wps                        Women, Peace and Security Index
#> 13                un_mvi                UN Multidimensional Vulnerability Index
#> 14         debt_distress                           Debt-distress classification
#> 15                 searo            Sexual Exploitation and Abuse Risk Overview
#> 16 disaster_displacement                       Disaster Displacement Risk Model
#> 17 internal_displacement                            Internal Displacement Index
#>                       source_version publication_date retrieval_date
#> 1  2025 prototype (2050 pessimistic)             <NA>     2026-09-11
#> 2                        2026 v0.7.2       2026-03-31     2026-08-04
#> 3                            2026-06       2026-06-30     2026-08-04
#> 4                               2025             <NA>     2026-08-04
#> 5           States of Fragility 2025             <NA>     2026-08-04
#> 6                               2025             <NA>     2026-08-04
#> 7              2026 release+e854c7fe             <NA>     2026-08-25
#> 8      Human Development Report 2025             <NA>     2026-08-04
#> 9                    Global MPI 2025             <NA>     2026-08-04
#> 10                     2025+6d7af17a             <NA>     2026-08-26
#> 11                              2021             <NA>     2026-08-04
#> 12                           2025/26             <NA>     2026-08-04
#> 13          High-Level Panel results             <NA>     2026-08-04
#> 14                        2026-03-31       2026-03-31     2026-08-04
#> 15                         2026 v1.2             <NA>     2026-08-04
#> 16                          GDRM 2.0             <NA>     2026-08-04
#> 17              IDI 2023 publication             <NA>     2026-08-04
#>         cadence expected_publication_window             status
#> 1     irregular                        <NA> irregular_schedule
#> 2        annual                      8,9,10      expected_soon
#> 3       monthly                        <NA>      expected_soon
#> 4        annual                    10,11,12   latest_published
#> 5      biennial                        <NA>   latest_published
#> 6        annual                        9,10      expected_soon
#> 7        annual                        <NA>   latest_published
#> 8        annual                        <NA>   latest_published
#> 9        annual                     9,10,11      expected_soon
#> 10       annual                          10   latest_published
#> 11    irregular                        <NA> irregular_schedule
#> 12     biennial                        <NA>   latest_published
#> 13    irregular                        <NA> irregular_schedule
#> 14 event_driven                        <NA> irregular_schedule
#> 15       annual                        <NA>   latest_published
#> 16    irregular                        <NA> irregular_schedule
#> 17    irregular                        <NA> irregular_schedule
#>                                               status_reason
#> 1              The publisher has no fixed release schedule.
#> 2  The source is in its expected annual publication window.
#> 3                The next monthly release is expected soon.
#> 4            This is the latest approved publisher edition.
#> 5           This is the latest approved multi-year edition.
#> 6  The source is in its expected annual publication window.
#> 7            This is the latest approved publisher edition.
#> 8            This is the latest approved publisher edition.
#> 9  The source is in its expected annual publication window.
#> 10           This is the latest approved publisher edition.
#> 11             The publisher has no fixed release schedule.
#> 12          This is the latest approved multi-year edition.
#> 13             The publisher has no fixed release schedule.
#> 14             The publisher has no fixed release schedule.
#> 15           This is the latest approved publisher edition.
#> 16             The publisher has no fixed release schedule.
#> 17             The publisher has no fixed release schedule.
```
