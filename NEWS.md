# globalvuln 0.2.0

* Added `clif_vi`: the Climate Finance Vulnerability Index 2025 prototype,
  using the 2050 pessimistic projection for 188 countries. Includes an
  automated adapter, bundled and approved online data, provenance, and explorer
  methodology. Higher scores are worse; recalculated ranks contribute to
  top-10 and top-20 summaries when selected.
* Fixed combined pipeline validation to retain failures and warnings instead
  of silently reducing unnamed validation results to a pass.
* Recheck source downloads on every pipeline run so revisions at stable URLs
  are detected even when their discovery metadata is unchanged.
* Added a registry-driven `{targets}` data pipeline with strict validation,
  change analysis, provenance, and atomic publication.
* Added automated adapters for 15 public sources and a validated manual
  ingestion adapter for the IDMC disaster-displacement model.
* Added `globalvuln_data()` for explicit bundled or approved live data access.
* Added `source_status()` for cadence-aware source freshness information.
* Added a versioned static `{pins}` board and scheduled update pull requests.

# globalvuln 0.1.0

* Added `collate_indices()` to combine a user-selected set of indices in wide
  or long format, with rank-based top-10 and top-20 counts and proportions.
* Added a consistently structured dataset for every individual index.
* Added publisher, edition, retrieval, checksum, licensing, and coverage
  metadata.
