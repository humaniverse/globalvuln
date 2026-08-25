# Changelog

## globalvuln 0.2.0

- Added a registry-driven [targets](https://docs.ropensci.org/targets/)
  data pipeline with strict validation, change analysis, provenance, and
  atomic publication.
- Added automated adapters for 15 public sources and a validated manual
  ingestion adapter for the IDMC disaster-displacement model.
- Added
  [`globalvuln_data()`](https://humaniverse.github.io/globalvuln/reference/globalvuln_data.md)
  for explicit bundled or approved live data access.
- Added
  [`source_status()`](https://humaniverse.github.io/globalvuln/reference/source_status.md)
  for cadence-aware source freshness information.
- Added a versioned static [pins](https://pins.rstudio.com/) board and
  scheduled update pull requests.

## globalvuln 0.1.0

- Added
  [`collate_indices()`](https://humaniverse.github.io/globalvuln/reference/collate_indices.md)
  to combine a user-selected set of indices in wide or long format, with
  rank-based top-10 and top-20 counts and proportions.
- Added a consistently structured dataset for every individual index.
- Added publisher, edition, retrieval, checksum, licensing, and coverage
  metadata.
