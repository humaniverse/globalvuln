# Data pipeline maintenance

The production data build is owned by this repository. It does not read from a
neighbouring `ad-hoc-analysis` checkout.

## Run the pipeline

From a clean checkout with package dependencies installed:

```r
targets::tar_make()
```

To inspect the graph or rerun source branches during adapter development:

```r
targets::tar_manifest()
targets::tar_make(names = tidyselect::starts_with("inform_severity"))
```

The daily and manually dispatchable workflow in
`.github/workflows/update-data.yaml` runs the same graph, validates the static
board, runs package tests and `R CMD check`, and opens a pull request only when
approved-data files changed. It never writes directly to `main`.

## Approved and working state

- `sources.yml` is the authoritative catalogue for all 16 indices.
- `approved/humanitarian_indices.rds` retains canonical historical editions.
- `approved/source_manifest.csv` records approved source versions and hashes.
- `../data-published/` is the versioned static pins board deployed under
  `https://humaniverse.github.io/globalvuln/data/`.
- `_targets/`, downloads, and generated review reports are working state and
  are not committed.

Raw publisher files are downloaded ephemerally. Their URLs, checksums,
retrieval dates, licensing information, and redistribution policy are retained
in provenance. The pipeline validates file signatures before parsing so an HTML
error page cannot be accepted as a workbook or PDF.

## Adapter status

All 16 sources implement the complete contract:

```text
discover -> download -> parse -> standardise -> validate -> compare
```

Fifteen sources use scheduled public discovery/downloads. Disaster displacement
remains `automated: false` because IDMC does not provide a stable downloadable
country table for GDRM 2.0. Its implemented manual adapter applies the same
schema, country, range, uniqueness, comparison, and publication gates.

## Manual disaster-displacement update

1. Export one country row per ISO3 from IDMC GDRM 2.0 using the Current
   scenario, AAD metric, Multi-hazard/All scope, and Country aggregation.
2. Populate a copy of `manual/disaster-displacement-template.csv`. Keep the
   completed raw export outside version control, for example at
   `_targets/manual/disaster-displacement.csv`.
3. Build and validate a candidate:

```r
source("R/common-schema.R")
invisible(lapply(list.files("data-raw/R", "[.]R$", full.names = TRUE), source))

result <- process_manual_source(
  "disaster_displacement",
  "_targets/manual/disaster-displacement.csv"
)
pipeline <- assemble_pipeline(
  list(result),
  read_approved_history(),
  read_approved_manifest()
)
publish_pipeline(pipeline)
```

Review the generated change report and package diff through the same pull
request gate as an automated source update.

## Repair a broken adapter

1. Reproduce the failing source locally and preserve the validation message.
2. Confirm the publisher URL, content type, release metadata, and licence.
3. Update only the affected `data-raw/R/source-<index-id>.R` adapter where
   possible; structural changes should fail loudly.
4. Add or update the smallest redistributable fixture covering the new format.
5. Run the source tests, `targets::tar_make()`, the board validator, and
   `rcmdcheck::rcmdcheck(args = "--no-manual")`.
6. Review `artifacts/update-summary.md` and all country/coverage changes before
   approving the data update pull request.

Country-name exceptions belong in `overrides/countries.csv` with a reason and
introduction date. Do not add fuzzy mappings that silently accept unresolved
publisher names.
