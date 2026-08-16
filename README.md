# globalvuln

`globalvuln` is an R data package containing country-level data from published
global vulnerability, fragility, development, hunger, health, gender, debt,
safeguarding, and displacement indices.

Publisher scores remain on their original scales. The package standardises
only rank and decile direction, so rank 1 and decile 1 always mean **most
vulnerable** within the countries scored by that index.

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("matthewgthomas/globalvuln")
```

## Data

The main analysis-ready dataset is `humanitarian_indices_country`: one row for
each of 195 United Nations member or observer states, with score, vulnerability
rank, and vulnerability decile columns for all 16 indices.

```r
library(globalvuln)

humanitarian_indices_country[
  humanitarian_indices_country$iso3 == "AFG",
  c("country", "inform_risk_score", "inform_risk_rank", "top_10_count")
]
```

`humanitarian_indices_long` contains the same collection as a complete
country-index audit table. Individual index datasets share that table's schema
and use the source identifiers as their object names:

```r
data(inform_risk)

head(inform_risk[!is.na(inform_risk$score),
                 c("country", "score", "rank", "decile")])

data(package = "globalvuln")
```

The individual objects are `inform_risk`, `inform_severity`,
`underfunded_crisis`, `oecd_fragility`, `worldrisk`, `nd_gain`, `hdi`, `mpi`,
`ghi`, `ghs`, `wps`, `un_mvi`, `debt_distress`, `searo`,
`disaster_displacement`, and `internal_displacement`.

Use `humanitarian_index_sources` for publisher URLs, editions, reference years,
retrieval dates, source-file checksums, coverage, and licensing notes.

## Interpretation

- Rankings and deciles are calculated within each index's published exact
  numeric coverage, not across all 195 countries.
- Ties use minimum rank. Deciles are
  `min(10, floor(10 * (rank - 1) / n_scored) + 1)`, so tied groups can make a
  decile contain more than exactly 10% of scored countries.
- `top_10_count` counts decile 1 appearances; `top_20_count` counts decile 1 or
  2 appearances; and `indices_ranked_count` is the available denominator for
  each country.
- Debt distress is a published classification with a derived ordinal value. It
  is not ranked or included in summary counts.
- Global Hunger Index censored values and ranges are retained as score labels
  and are not assigned invented numeric scores.
- Disaster Displacement Risk Model fields are present but missing because no
  stable downloadable country table was available at the 4 August 2026 data
  snapshot.
- No scores are imputed and no cross-index meta-score is produced.

## Sources and reuse

The package distributes harmonised country-level data and provenance metadata,
not the publishers' raw files. Source data remain the property of their
publishers and are subject to their applicable terms. Cite the relevant
publisher or index edition when using an individual series; details are in
`humanitarian_index_sources`.
