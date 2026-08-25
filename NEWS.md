# globalvuln 0.2.0

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
