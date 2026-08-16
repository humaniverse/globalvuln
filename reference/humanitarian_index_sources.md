# Sources and provenance for the humanitarian indices

Publisher, edition, retrieval, licensing, checksum, and coverage
metadata for every index source and the United Nations M49 geography
source used to create the package datasets.

## Usage

``` r
humanitarian_index_sources
```

## Format

A data frame with 17 rows and 17 variables:

- source_id:

  Stable source identifier. For index sources this equals `index_id`;
  `un_m49` identifies the geography source.

- source_name:

  Human-readable source or index name.

- edition:

  Publisher edition or release.

- reference_year:

  Year or period represented by the source.

- source_url:

  Publisher landing page.

- download_url:

  URL used to retrieve the source snapshot, if any.

- local_file:

  Path used by the source processing pipeline.

- retrieval_date:

  Date on which the source snapshot was retrieved.

- sha256:

  SHA-256 checksum of the source snapshot.

- file_bytes:

  Size of the source snapshot in bytes.

- source_status:

  Availability or manual-input status.

- n_numeric_scores:

  Number of exact numeric scores parsed.

- n_labelled_records:

  Number of publisher labels retained.

- n_ranked:

  Number of observations included in ranking.

- coverage_ok:

  Whether observed coverage passed its configured check.

- license_notes:

  Publisher attribution or reuse note.

- source_notes:

  Processing or interpretation note.

## Source

Publisher pages in the `source_url` column. Metadata snapshot: 4 August
2026.

## Details

Raw source files remain the property of their publishers and are
governed by their respective terms. Users should cite the relevant
publisher when using an index. The `local_file` paths describe the
reproducible source pipeline and are not paths within an installed
`globalvuln` package.

## See also

[humanitarian_indices_country](http://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_country.md),
[humanitarian_indices_long](http://matthewgthomas.co.uk/globalvuln/reference/humanitarian_indices_long.md)

## Examples

``` r
data(humanitarian_index_sources)

humanitarian_index_sources[
  humanitarian_index_sources$source_id == "inform_risk",
  c("source_name", "edition", "source_url")
]
#>   source_name     edition
#> 1 INFORM Risk 2026 v0.7.2
#>                                                                 source_url
#> 1 https://drmkc.jrc.ec.europa.eu/inform-index/INFORM-Risk/Results-and-data
```
