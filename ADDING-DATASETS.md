# Adding a new dataset

This guide is for adding a new index to `globalvuln`. To publish a new
edition of an index that is already supported, follow the update and
adapter-repair instructions in
[`data-raw/README.md`](https://humaniverse.github.io/globalvuln/data-raw/README.md)
instead.

A new dataset must be country-level, have a documented publisher and
methodology, and be compatible with the package’s 195-country schema.
The package retains publisher scores on their original scale; it does
not impute missing values or create a cross-index score.

## 1. Choose the identifier and review the source

Choose a stable, lower-case `snake_case` identifier. The same identifier
is used for the registry key, adapter functions, package data object,
and file name. Changing it later is an API-breaking change.

Before writing an adapter, record:

- the publisher, landing page, direct data URL, methodology, licence,
  and redistribution terms;
- the publication cadence and, for annual sources, likely publication
  months;
- whether higher or lower scores indicate greater vulnerability;
- the expected score range and country coverage;
- whether the score is numeric and rankable, and whether its ranks
  should contribute to the package’s top-10 and top-20 summaries; and
- whether a stable public download can support unattended updates. If it
  cannot, plan a documented manual input and set `automated: false`.

Do not commit a publisher’s raw file unless its terms permit
redistribution. Normal downloads belong under `_targets/` and are
intentionally ignored.

## 2. Register the dataset

Add the identifier to `.index_ids` in `R/common-schema.R`. This is the
package’s authoritative list of supported indices.

Add a full entry to `data-raw/sources.yml`. Use a nearby source with the
same file type and cadence as a model. The registry validator requires
the source URLs to use HTTPS and recognises these values:

- `cadence`: `monthly`, `quarterly`, `annual`, `biennial`, `triennial`,
  `event_driven`, or `irregular`;
- `vulnerability_direction`: `higher_is_worse` or `lower_is_worse`; and
- `expected_file_type`: `csv`, `tsv`, `html`, `xlsx`, `zip`, or `pdf`.

Set realistic `expected_min_countries`, `expected_max_countries`,
`score_min`, and `score_max` values. These are publication gates, not
descriptive metadata. Use `redistribution_allowed: null` when the terms
are unclear rather than assuming permission.

Set `implemented: true` only after all four adapter functions described
below exist. An automated source must also have `implemented: true`.

Add the source’s `name`, `cadence`, and `expected_publication_months` to
the reduced installed catalogue at `inst/extdata/sources.yml`. Do not
copy the full maintenance entry into this file; the installed package
uses only those three fields for
[`source_status()`](https://humaniverse.github.io/globalvuln/reference/source_status.md).

If parsing needs a package not already listed, add it to `Suggests` in
`DESCRIPTION` and to `tar_option_set(packages = ...)` in `_targets.R`.

## 3. Implement the adapter

Create `data-raw/R/source-<index-id>.R`. An implemented adapter must
define:

``` r
discover_<index_id> <- function(registry_entry, approved_manifest) { ... }
parse_<index_id> <- function(path, discovery) { ... }
standardise_<index_id> <- function(parsed, discovery, geography, overrides) { ... }
validate_<index_id> <- function(data, discovery) { ... }
```

The pipeline calls these functions as:

``` text
discover -> download -> parse -> standardise -> validate -> compare
```

### Discover and download

Use `discover_fixed_source()` for a stable direct URL or
`discover_landing_file()` when the newest release must be selected from
a landing page. A custom discovery function must return a
`new_discovery()` result containing at least `index_id`,
`source_version`, and `url`.

The common downloader verifies the configured file signature before
parsing. If a download is a container or includes unstable page content,
define an optional `prepare_source_file_<index_id>()` function that
returns the prepared path. Preparation must be deterministic so
unchanged publisher data has an unchanged checksum.

For a manual source, provide a version-controlled blank template under
`data-raw/manual/`, document how to export and populate it in
`data-raw/README.md`, and process completed files with
`process_manual_source()`. Keep completed publisher exports outside
version control.

### Parse

Make schema changes fail loudly. Do not select columns only by position
unless the publisher format makes that unavoidable and the layout is
covered by a fixture test.

Return `new_parsed_source()` with one publisher row per country and
these fields:

| Field | Requirement |
|----|----|
| `source_country` | Publisher’s country label. |
| `iso3` | Upper-case ISO3 when supplied; otherwise `NA` for later name mapping. |
| `score` | Exact numeric publisher value, or `NA` for censored/classified values. |
| `score_label` | Publisher display label when it carries information. |
| `reference_year` | Country-specific year or period, if available. |

Also supply stable `source_version`, `edition`, and `reference_period`
values. Supply `publication_date` and `methodology_version` when known.
Exclude regions, income groups, and other aggregates explicitly, and
reject duplicate countries.

### Standardise

Most numeric indices can call `standardise_numeric_adapter()`. It maps
country names, expands the source to the master 195-country grid,
preserves the publisher score, and calculates consistently directed
ranks and deciles.

Do not silently add fuzzy country matches. Add a reviewed exception to
`data-raw/overrides/countries.csv`, including its reason and
introduction date. Reject unexpected non-country ISO3 codes unless they
are explicitly allowed and discarded by the adapter.

Set `rankable = FALSE` for classifications or measures that must not be
ranked. Set `eligible_for_counts: false` in the registry when an index’s
ranks should not affect cross-index top-10 and top-20 summaries.

### Validate

Use `validate_numeric_adapter()` where possible, then add
source-specific checks for invariants such as edition labels, required
categories, row counts, or permissible missingness. Validation should
reject a plausible-looking but wrong worksheet, column, metric,
scenario, or geographic level.

The common validator also requires a 195-row grid, valid and unique ISO3
keys, a non-empty source version, at least one numeric score, and valid
ranks and deciles. A wholly non-numeric dataset therefore needs an
explicit design change to the common contract before it can be added.

## 4. Add offline tests

Add the smallest redistributable fixture that represents the publisher
format to `tests/testthat/fixtures/`, or generate a minimal file in the
test when that is clearer. Never make ordinary unit tests depend on a
live publisher site.

At minimum, test that:

- discovery selects the intended release;
- parsing selects the intended country, score, label, and edition
  fields;
- aggregates and duplicate country rows are rejected or removed
  deliberately;
- malformed or changed schemas fail with a useful message;
- standardisation returns 195 unique ISO3 rows; and
- source-specific validation catches the most likely silent failure
  mode.

Adapter tests normally live in `tests/testthat/test-source-adapters.R`;
a complex source can use `tests/testthat/test-source-<index-id>.R`. Add
the new ID to the local `index_ids` vector in
`tests/testthat/test-data.R`, and update fixed-count expectations such
as the
[`source_status()`](https://humaniverse.github.io/globalvuln/reference/source_status.md)
row count in `tests/testthat/test-live-data.R`.

## 5. Update package data and documentation

Before the first full publication, append a placeholder row for the new
`source_id` to `data/humanitarian_index_sources.rda`, preserving its
existing column types and the `un_m49` row.
`write_package_data_if_changed()` currently updates an existing
provenance row; it does not create one. The successful pipeline run will
replace the placeholder’s edition, checksum, coverage, and other source
fields. The approved history and approved manifest do not need
placeholder rows: the pipeline appends their first approved candidate.

For example, replace the first three values below and run this once from
the package root immediately before the full pipeline:

``` r

index_id <- "new_index"
index_name <- "New Index"
homepage_url <- "https://publisher.example/index"

environment <- new.env(parent = emptyenv())
load("data/humanitarian_index_sources.rda", envir = environment)
sources <- environment$humanitarian_index_sources

placeholder <- sources[1L, , drop = FALSE]
placeholder[1L, ] <- NA
placeholder$source_id <- index_id
placeholder$source_name <- index_name
placeholder$source_url <- homepage_url
placeholder$source_status <- "pending"
placeholder$coverage_ok <- FALSE

geography <- sources[sources$source_id == "un_m49", , drop = FALSE]
sources <- sources[sources$source_id != "un_m49", , drop = FALSE]
humanitarian_index_sources <- rbind(sources, placeholder, geography)
save(
  humanitarian_index_sources,
  file = "data/humanitarian_index_sources.rda",
  version = 3,
  compress = "xz"
)
```

Update the public documentation and API references:

- add the alias and dataset description in `R/data.R`, including the
  revised dataset and provenance row counts;
- add the identifier to the `indices` documentation in
  `R/collate-indices.R`;
- add the dataset to the README’s object list and index catalogue;
- update totals in `README.md` and `data-raw/README.md`;
- update `pkgdown/assets/indices-explorer.html` and its validation
  expectation in `data-raw/validate-indices-explorer.mjs`; and
- record the addition in `NEWS.md`.

Find hard-coded counts and lists before declaring the work complete:

``` sh
rg -n '16 indices|16 sources|Sixteen|17 rows|index_ids' \
  README.md R data-raw tests pkgdown
```

Regenerate Rd files after editing roxygen comments:

``` r

roxygen2::roxygenise()
```

## 6. Build, review, and verify

For an automated source, run the complete pipeline from the package
root. A first edition is treated as a changed candidate and is appended
to approved history after validation:

``` r

targets::tar_make()
```

For a manual source, build its result with `process_manual_source()`,
pass that result to `assemble_pipeline()`, and call `publish_pipeline()`
as shown in the manual-update example in `data-raw/README.md`.

Review `artifacts/update-summary.md`, the new `data/<index-id>.rda`, the
approved history and manifest, and the versioned board. Confirm country
coverage, missingness, score direction, ranks, licence notes, source
version, reference period, and checksum before accepting the generated
files.

Then run the same checks as CI:

``` sh
Rscript data-raw/validate-pins-board.R data-published
node data-raw/validate-indices-explorer.mjs
```

``` r

testthat::test_local(stop_on_failure = TRUE)
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "warning")
```

Commit the generated package snapshot, approved history and manifest,
installed manifest, and versioned board along with the code and
documentation. Do not commit `_targets/`, downloaded source files, or
`artifacts/`.

## Definition of done

A new dataset is ready for review when it can be loaded with
`data(<index_id>)`, selected in both layouts of
[`collate_indices()`](https://humaniverse.github.io/globalvuln/reference/collate_indices.md),
retrieved through
[`globalvuln_data()`](https://humaniverse.github.io/globalvuln/reference/globalvuln_data.md),
and reported by
[`source_status()`](https://humaniverse.github.io/globalvuln/reference/source_status.md);
its adapter and validation tests pass offline; the board validator and
`R CMD check` pass; and the README, generated help, provenance,
explorer, and source licence all agree with the approved data.
